defmodule Main do
  require Logger
  server_self= %ServerInfo{port: 52000, ip: ['192.168.0.50']}
  server_self_2= %ServerInfo{port: 52001, ip: ['192.168.0.50']}
  server_self_3= %ServerInfo{port: 52002, ip: ['192.168.0.50']}
  server_self_4= %ServerInfo{port: 52003, ip: ['192.168.0.50']}

  {:ok, pid} = AppTCPServer.start_link([])
  #Logger.info("Genserver started with pid: #{inspect pid}")
  spawn fn-> AppTCPServer.accept(server_self.port, pid) end
  {:ok, pid} = AppTCPServer.start_link([])
  #Logger.info("Genserver started with pid: #{inspect pid}")
  spawn fn-> AppTCPServer.accept(server_self_2.port, pid) end
  {:ok, pid} = AppTCPServer.start_link([])
  #Logger.info("Genserver started with pid: #{inspect pid}")
  spawn fn-> AppTCPServer.accept(server_self_4.port, pid) end
  {:ok, pid} = AppTCPServer.start_link([])
  #Logger.info("Genserver started with pid: #{inspect pid}")
  AppTCPServer.accept(server_self_3.port, pid)
end