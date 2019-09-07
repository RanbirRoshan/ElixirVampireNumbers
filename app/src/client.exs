defmodule Main do
  require Logger

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
  #IO.inspect(servers)
  #ans  = GenServer.call(pid, {:getAllVampiresInRange, 0, 10000},1000000)
  #t = Task.async(App, :findVampireNumbers, [0, 10000, self(), servers, length(servers)])
  #ans = Task.await(t, 1000000)
  ans = App.findVampireNumbers(0, 10000, self(), servers, length(servers))

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