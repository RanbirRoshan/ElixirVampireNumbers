defmodule Main do
  require Logger

  server1= %ServerInfo{port: 52000, ip: ['192.168.0.50']}
  server2= %ServerInfo{port: 52001, ip: ['192.168.0.50']}
  server3= %ServerInfo{port: 52002, ip: ['192.168.0.50']}
  server4= %ServerInfo{port: 52003, ip: ['192.168.0.50']}
  x=[server1,server2,server3,server4]

  {:ok, pid} = AppTCPServer.start([])
  #Logger.info("Genserver client started with pid: #{inspect pid}")

  AppTCPServer.connect(x, pid)
  Process.sleep(1000)

  servers = GenServer.call(pid, {:get_state})
  #ans  = GenServer.call(pid, {:getAllVampiresInRange, 10, 12},1000000)
  t = Task.async(App, :findVampireNumbers, [0, 127000, self(), servers, length(servers)])
  ans = Task.await(t, 1000000)

  IO.puts("Hello ******************************************* #{inspect ans}")
  Process.sleep(3000000)
end