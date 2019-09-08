defmodule Main do
  require Logger
  [arg1, arg2] = System.argv
  {arg1_val, _} = Integer.parse(arg1)
  {arg2_val, _} = Integer.parse(arg2)

  server1= %ServerInfo{port: 52009, ip: ['192.168.0.88']} #sid
  server2= %ServerInfo{port: 52000, ip: ['192.168.0.161']}
  #server3= %ServerInfo{port: 52003, ip: ['192.168.0.32']} #mukul
  server4= %ServerInfo{port: 52002, ip: ['192.168.0.91']}  #big brad
  #server5= %ServerInfo{port: 52004, ip: ['192.168.0.104']}
  #server6= %ServerInfo{port: 52005, ip: ['192.168.0.161']} # small brad
  x=[server1,server4, server2]#[server1, server2, server6, server3, server4]

  {:ok, pid} = AppTCPServer.start([])
  #Logger.info("Genserver client started with pid: #{inspect pid}")

  AppTCPServer.connect(x, pid)
  Process.sleep(1000)


  # capture initial time values

  :erlang.statistics(:runtime)

  :erlang.statistics(:wall_clock)
  servers = GenServer.call(pid, {:get_state})
  arg1_val =
    if (arg1_val<1000) do
      1000
    else
      arg1_val
    end

  ans =
    if (arg2_val>999 && arg2_val >= arg1_val) do
      App.findVampireNumbers(arg1_val, arg2_val, self(), servers, length(servers), 0, arg2_val-arg1_val)
    else
      %{}
    end
  {_, time_wall} = :erlang.statistics(:wall_clock)

  {_, time_run} = :erlang.statistics(:runtime)



  ratio =

    if (time_wall==0) do

      0

    else

      time_run/time_wall

    end
  #Process.sleep(100000)

  IO.puts("CPU Time: #{time_run} ms Real Time: #{time_wall} ms. Ratio : #{ratio}")
  Process.sleep(1000)

  if (:erlang.map_size(ans) > 0) do
    keys = Map.keys(ans) |> Enum.sort
    for key <- keys do
      IO.write(key)
      IO.write(" ")
      for elem <- Map.get(ans, key) do
        for inner_elem <- elem do
          IO.write(inner_elem)
          IO.write(" ")
        end
      end
      IO.puts("")
    end
  end
end