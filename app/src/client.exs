defmodule Main do
  require Logger

  server1= %ServerInfo{port: 52000, ip: ['192.168.0.50']}
  server2= %ServerInfo{port: 52001, ip: ['192.168.0.50']}
  server3= %ServerInfo{port: 52002, ip: ['192.168.0.50']}
  server4= %ServerInfo{port: 52003, ip: ['192.168.0.50']}
  x=[server1,server2,server3,server4]

  {:ok, pid} = AppTCPServer.start_link([])
  #Logger.info("Genserver client started with pid: #{inspect pid}")

  AppTCPServer.connect(x, pid)
  Process.sleep(3000)

  ans = GenServer.call(pid, {:getAllVampiresInRange, 125460 , 125461},1000000)

  IO.inspect(ans)

  IO.puts("Hello")
  Process.sleep(3000000)
end