defmodule ServerInfo do
  @derive Jason.Encoder
  defstruct port: 52000, ip: ['127.0.0.1']

  def decodeFunction(data) do
    ret = Map.new data, fn({key, value}) ->
      {String.to_atom(key), value}
    end
    struct(ServerInfo, ret)
  end
end

defmodule TCPReq do
  @derive Jason.Encoder
  defstruct type: "request", pid: "", operation: 0, data: []

  def decodeFunction(data) do
    ret = Map.new data, fn({key, value}) ->
                              {String.to_atom(key), value}
    end
    #IO.inspect(ret)
    struct(TCPReq, ret)
  end
end

defmodule AppTCPServer do
  require Logger
  use GenServer, restart: :permanent

  @request_str "request"
#  @response_str "response"
  @connect_others "connect_others"
  @execute_task "execute_task"

  @impl true
  def terminate(state, reason) do
    Logger.info("Termination. Reason: #{reason}. State: #{inspect state}")
  end

  @impl true
  def init(init_arg) do
    Process.flag(:trap_exit, false)
    {:ok, init_arg}
  end

  #@impl true
  def start(initial_state) do
    #Logger.info("Starting server with an inital state: #{inspect initial_state}")
    GenServer.start(__MODULE__, initial_state, [])
  end


  def connect(server_list, genserver_pid) do
    for server <- server_list do
      other = List.delete(Enum.at(Enum.chunk_by(server_list, &(&1 == server)),0), server)
      GenServer.call(genserver_pid,{:connect,server,other, genserver_pid}, 1000000)
    end
  end

  def connect(server, others, state, genPid) do
    #Logger.info("Connecting to server #{inspect server}.")

    opts=[keepalive: true, nodelay: true, active: false, delay_send: false, reuseaddr: true]

    {:ok, socket} = :gen_tcp.connect(Enum.at(server.ip,0), server.port, opts)

    Logger.info("Connected to #{server.ip}:#{server.port}")

    state = state ++ [socket]

    for other<-others do

      data = %TCPReq{type: @request_str, pid: 0, operation: @connect_others, data: [other]}
      {:ok, response} = Jason.encode(data)
      write_line(socket, response)
    end

    spawn fn -> serveMe(socket, genPid, "") end
    #Logger.info("#{inspect self()}  Total known server: #{length(state)}")
    state
  end

  @impl true
  def handle_call({:connect_others, server, genserver_pid}, _from, state) do
    server = ServerInfo.decodeFunction(server)
    state = connect(server, [], state, genserver_pid)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:connect, server, others, genPid}, _from, state) do
    state= connect(server, others, state, genPid)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:addServer, server}, _from, state) do
    #Logger.info("Connected to server #{inspect server}.")
    state=state++[server]
    #Logger.info("#{inspect self()} Total known server: #{length(state)}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:getAllVampiresInRange, range_start, range_end}, _from, state) do
    IO.inspect(state)
    #t = Task.async(App, :findVampireNumbers, [0, 10000, self(), state, length(state)])
    #ans = Task.await(t, 1000000)
    ans = App.findVampireNumbers(0, 10000, self(), state, length(state), 0)
    #t = Task.async(App, :findVampireNumbers, [range_start, range_end, self(), state, length(state)])
    #val = Task.await(t, 1000000)
    #val = App.findVampireNumbers(range_start, range_end, self(), state, length(state))
    {:reply, ans, state}
  end

  @impl true
  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def accept(port, genserver_pid) do
    {:ok, socket} =
      :gen_tcp.listen(port, [keepalive: true,  active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket, genserver_pid)
  end

  defp loop_acceptor(socket, genserver_pid) do

    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, {peer_ip, port}} =:inet.peername(client)
    #peer_ip = to_string(peer_ip)
    Logger.info("Connected to #{inspect peer_ip}:#{port}")
    spawn fn ->
      Process.flag(:trap_exit, true)
      GenServer.call(genserver_pid, {:addServer, client}, 100000)
      serveMe(client, genserver_pid, "")
    end
    loop_acceptor(socket, genserver_pid)
  end

  def sendTCPData(socket, data) do

    data = %TCPReq{type: @request_str, pid: "#{inspect self()}", operation: @execute_task, data: data}
    {:ok, response} = Jason.encode(data)
    write_line(socket, response)
  end

  defp serveMe(socket, genPid, old_trailing) do
    {data, trailing} = socket |> read_line(old_trailing)
    spawn fn ->
      #for data <- data_list do
        #if data != "" do
          {:ok, data} = Jason.decode(data)# (data, as: %TCPReq)
          #IO.inspect(data)
          data = TCPReq.decodeFunction(data)
          #IO.inspect(data)
          if (data.type == @request_str) do
            cond do
              data.operation == @connect_others ->
                GenServer.call(genPid, {:connect_others,Enum.at(data.data,0, genPid), genPid}, 1000000)
                u=%TCPReq{type: "response",operation: 0, data: "Connected"}
                {_response, y}=Jason.encode(u)
                write_line(socket, y)
              data.operation == @execute_task ->
                servers = GenServer.call(genPid, {:get_state})

                res = App.executeTask(data.data, servers)

                u=%TCPReq{type: "response",operation: 0, data: res, pid: data.pid}
                {_response, y}=Jason.encode(u)

                write_line(socket, y)

                Logger.info ("Response sent: #{inspect res, charlists: :as_lists}")
              true ->
                u=%TCPReq{type: "response", pid: 1, operation: 0, data: ["Invalid Operation"]}
                {_response, y}=Jason.encode(u)
                write_line(socket, y)
            end
          else
            if (data.pid != "") do
              len = String.length(data.pid)
              send :erlang.list_to_pid(String.to_charlist(String.slice(data.pid, 4, len-4))), data.data
            end
          end
        #end
      #end
    end
    spawn fn -> serveMe(socket, genPid, trailing) end
  end

  defp parseString(str) do
    {leading, trailing} = :string.take(str, [36], true)
    #IO.puts("leading: #{leading} trailing:#{trailing} str:#{str}")
    cond do
      leading == "" ->
        {_waste, trailing} = :string.take(trailing, [36], false)
        {leading, trailing}
      trailing == "" ->
        {trailing, leading}
      true ->
        {_waste, trailing} = :string.take(trailing, [36], false)
        {leading, trailing}
    end
  end

  defp read_line(socket, previous_trailing) do
    {leading, trailing} = parseString(previous_trailing)
    if (leading != "") do
      {leading, trailing}
    else
      {:ok, data} = :gen_tcp.recv(socket, 0)
      #data = String.split(to_string(data), "$") |> Enum.reject(fn x -> x=="" end)
      data = trailing <> to_string(data)
      read_line(socket, data)
    end
  end

  def write_line(socket, line) do
    #IO.inspect(socket)
    line = line <> "$"
    :gen_tcp.send(socket, line)
  end
end