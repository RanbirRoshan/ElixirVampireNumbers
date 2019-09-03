defmodule Main do
  opts=[:binary, keepalive: true, nodelay: true, active: false, delay_send: true, reuseaddr: true]
  {:ok, socket_1} = :gen_tcp.connect('192.168.0.50', 52052, opts)
  opts=[:binary, keepalive: true, nodelay: true, active: false, delay_send: true, reuseaddr: true]
  {:ok, socket_2} = :gen_tcp.connect('192.168.0.50', 52052, opts)
  sockets = [socket_1,socket_2]
  IO.puts "hello world!"
  #num=Integer.digits(1234)
  task = Task.async(App, :findVampireNumbers , [1  , 1454600 , self()])
  #task = Task.async(ListLoop, :getPossibleNumsArray , [num, length(num)/2, 0, 0,  self()])
  #id = spawn(App, :findVampireNumbers , [1111, 1458, self()])

  Task.await(task,10000000)
  #Process.sleep(1000)
  IO.puts "hello world!"
  #{:ok, server_pid} = GenServer.start_link(AppServerClient, :ok, [])
  #response = AppServerClient.put_getPossibleNumsArray(server_pid, [1,2,3,4], 2, 0 ,0)
  #IO.puts("Response #{inspect server_pid}  #{inspect response , charlists: :as_lists}")
  #AppTCPServer.accept(52052)
end