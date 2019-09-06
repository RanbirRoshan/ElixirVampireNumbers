defmodule Main do

  :observer.start()

  # read input from command line
  [arg1, arg2] = System.argv
  {arg1_val, _} = Integer.parse(arg1)
  {arg2_val, _} = Integer.parse(arg2)

  # capture initial time values
  :erlang.statistics(:runtime)
  :erlang.statistics(:wall_clock)

  # there are no vampire numbers less than 1000
  arg1_val =
    if (arg1_val<1000) do
      1000
    else
      arg1_val
    end

  ans =
    if (arg2_val>999 && arg2_val >= arg1_val) do

      #{:ok, pid} = GenServer.start(App, [])
      #GenServer.call(pid, {:findVampireNumbers, arg1_val, arg2_val, self()}, 1000000)

      task = Task.async(App, :findVampireNumbers , [arg1_val, arg2_val, self()])

      Task.await(task, 1000000)
    else
      %{}
    end

  {_, time_wall} = :erlang.statistics(:wall_clock)
  {_, time_run} = :erlang.statistics(:runtime)

  ratio = if (time_wall==0) do
    0
  else
    time_run/time_wall
  end

  if (:erlang.map_size(ans) > 0) do
    keys = Map.keys(ans)
    for key <- keys do
      IO.write(key)
      IO.write(" ")
      for elem <- Map.get(ans, key) do
        for inner_elem <- elem do
          IO.write(inner_elem)
          IO.write(" ")
        end
      end
      #IO.inspect(Map.get(ans, key))
      IO.puts("")
    end
  end

  #Process.sleep(100000)
  # IO.inspect(ans)
  IO.puts("CPU Time: #{time_run} ms Real Time: #{time_wall} ms. Ratio : #{ratio}")
end