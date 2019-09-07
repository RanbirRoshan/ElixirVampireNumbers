defmodule Main do
  require Logger
  [arg1, arg2] = System.argv
  {arg1_val, _} = Integer.parse(arg1)
  {arg2_val, _} = Integer.parse(arg2)

  #server1= %ServerInfo{port: 52000, ip: ['10.136.201.74']}
  #server2= %ServerInfo{port: 52000, ip: ['10.192.244.27']}
  server1= %ServerInfo{port: 52000, ip: ['127.0.0.1']}
  server2= %ServerInfo{port: 52001, ip: ['127.0.0.1']}
  #server3= %ServerInfo{port: 52002, ip: ['127.0.0.1']}
  #server4= %ServerInfo{port: 52003, ip: ['127.0.0.1']}
  #x=[server1, server2, server3, server4]
  x=[server1, server2]

  {:ok, pid} = AppTCPServer.start([])
  #Logger.info("Genserver client started with pid: #{inspect pid}")

  AppTCPServer.connect(x, pid)
  Process.sleep(1000)

  servers = GenServer.call(pid, {:get_state})
  arg1_val =
    if (arg1_val<1000) do
      1000
    else
      arg1_val
    end

  ans =
    if (arg2_val>999 && arg2_val >= arg1_val) do
      App.findVampireNumbers(arg1_val, arg2_val, self(), servers, length(servers))
    else
      %{}
    end

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