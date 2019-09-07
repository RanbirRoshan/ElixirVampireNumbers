defmodule Main do
  require Logger

  [arg1, arg2] = System.argv
  ip =  arg1
  {port, _} = Integer.parse(arg2)

  IO.puts("Trying to configure server to : #{ip} #{port}")

  server_self= %ServerInfo{port: port, ip: [ip]}
  {:ok, pid} = AppTCPServer.start([])
  AppTCPServer.accept(server_self.port, pid)
end