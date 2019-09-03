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
  use GenServer

  @request_str "request"
  @response_str "response"
  @connect_others "connect_others"
  @execute_task "execute_task"

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  #@impl true
  def start_link(initial_state) do
    #Logger.info("Starting server with an inital state: #{inspect initial_state}")
    GenServer.start_link(__MODULE__, initial_state, [])
  end

  def connect(server_list, genserver_pid) do
    for server <- server_list do
      other = List.delete(Enum.at(Enum.chunk_by(server_list, &(&1 == server)),0), server)
      GenServer.call(genserver_pid,{:connect,server,other}, 1000000)
    end
  end

  def connect(server, others, state) do
    #Logger.info("Connecting to server #{inspect server}.")

    opts=[keepalive: true, nodelay: true, active: false, delay_send: false, reuseaddr: true]

    {:ok, socket} = :gen_tcp.connect(Enum.at(server.ip,0), server.port, opts)

    state = state ++ [socket]

    for other<-others do

      data = %TCPReq{type: @request_str, pid: 0, operation: @connect_others, data: [other]}
      {:ok, response} = Jason.encode(data)
      #IO.inspect(others)
      #IO.puts(response)
      write_line(socket, response)
    end

    spawn fn -> serve(socket, self()) end
    #Logger.info("#{inspect self()}  Total known server: #{length(state)}")
    state
  end

  @impl true
  def handle_call({:connect_others, server, _genserver_pid}, _from, state) do
    server = ServerInfo.decodeFunction(server)
    #IO.inspect(state)
    ###IO.puts("Conencting to other server #{inspect server}")
    state = connect(server, [], state)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:connect, server, others}, _from, state) do
    state= connect(server, others, state)
    #IO.inspect(state)
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
    #t = Task.async(App, :findVampireNumbers, [range_start, range_end, self(), state, length(state)])
    #val = Task.await(t, 1000000)
    val = App.findVampireNumbers(range_start, range_end, self(), state, length(state))
    IO.puts("Final ans #{inspect val}")
    {:reply, val, state}
  end

  @impl true
  def handle_call({:execute_task, data, genserver_pid}, _from, state) do
    res = App.executeTask(data, state)
    IO.puts("#{inspect self()} Task ans #{inspect res}")
    {:reply, res, state}
  end

  def accept(port, genserver_pid) do
    {:ok, socket} =
      :gen_tcp.listen(port, [keepalive: true,  active: false, reuseaddr: true])
    #Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket, genserver_pid)
  end

  defp loop_acceptor(socket, genserver_pid) do

    {:ok, client} = :gen_tcp.accept(socket)
    spawn fn ->
      #{:ok, buffer_pid} = Buffer.create()
      Process.flag(:trap_exit, true)
      GenServer.call(genserver_pid, {:addServer, client}, 100000)
      serve(client, genserver_pid)
    end
    loop_acceptor(socket, genserver_pid)
  end

  def sendTCPData(socket, data) do

    data = %TCPReq{type: @request_str, pid: "#{inspect self()}", operation: @execute_task, data: data}
    {:ok, response} = Jason.encode(data)
    IO.puts("sending request to #{inspect socket} data: #{response}")
    write_line(socket, response)
  end

  defp serve(socket, genserver_pid) do
    data_list = socket |> read_line()
    IO.puts("#{inspect self} Connection Recieved #{data_list}")
    spawn fn ->
      for data <- data_list do
        #if data != "" do
          data = String.replace_suffix(data, "$", "")
          #IO.puts("#{inspect self()} #{inspect data} #{inspect data_list}"); #req = String.split(data,","); IO.inspect(req)
          {:ok, data} = Jason.decode(data)# (data, as: %TCPReq)
          #IO.inspect(data)
          data = TCPReq.decodeFunction(data)
          #IO.inspect(data)
          if (data.type == @request_str) do
            cond do
              data.operation == @connect_others ->
                GenServer.call(genserver_pid, {:connect_others,Enum.at(data.data,0), genserver_pid}, 1000000)
                u=%TCPReq{type: "response",operation: 0, data: "Connected"}
                {_response, y}=Jason.encode(u)
                write_line(socket, y)
              data.operation == @execute_task ->
                IO.puts("#{inspect self()} tasking")
                res = GenServer.call(genserver_pid, {:execute_task, data.data, genserver_pid}, 1000000)
                IO.puts("#{inspect self()} Task result recieved #{inspect res}")
                u=%TCPReq{type: "response",operation: 0, data: res, pid: data.pid}
                {_response, y}=Jason.encode(u)
                IO.puts("sending")
                write_line(socket, y)
              true ->
                u=%TCPReq{type: "response", pid: 1, operation: 0, data: ["Invalid Operation"]}
                {_response, y}=Jason.encode(u)
                write_line(socket, y)
            end
          else
            Logger.info("Response Recieved: #{inspect data}")
            if (data.pid != "") do
              len = String.length(data.pid)
              send :erlang.list_to_pid(String.to_charlist(String.slice(data.pid, 4, len-4))), data.data
            end
          end
        #end
      end
    end
    IO.puts("#{inspect self} Waiting for next Connection Recieved")
    serve(socket, genserver_pid)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    IO.puts("#{inspect self()} #{inspect data}")
    data = String.split(to_string(data), "$") |> Enum.reject(fn x -> x=="" end)
    #IO.puts("#{inspect self()} after split #{data}")
    #IO.puts("#{inspect self()} after split 2 #{inspect data}")
    data
  end

  def write_line(socket, line) do
    #IO.inspect(socket)
    line = line <> "$"
    :gen_tcp.send(socket, line)
  end
end