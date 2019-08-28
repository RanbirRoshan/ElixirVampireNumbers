defmodule Main do
  IO.puts "hello world!"
  task = Task.async(App, :findVampireNumbers , [0, 10000, self()])
  #id = spawn(App, :findVampireNumbers , [1111, 1458, self()])

  Task.await(task)
  #Process.sleep(1000)
  IO.puts "hello world!"
end