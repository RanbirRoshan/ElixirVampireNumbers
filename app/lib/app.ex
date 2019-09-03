import Bitwise

defmodule ListLoop do
  @doc """
  getPossibleNumsArray The code to end the recursion in the function
  """
  def getPossibleNumsArray(_list, len, cur_len, val, parent) when len==cur_len do
    digit_count = Integer.digits(val, 10) |> length

    # consider only the values that are of required length
    if digit_count == len do
      #[val]
      send(parent, {:response, [val]})
    else
      #[]
      send(parent, {:response, []})
    end
  end

  def getPossibleNumsArray(list, len, cur_len, val, parent) do
    doRecurse(list, len, cur_len, val, 0, parent)
  end

  def doRecurse(list, len, cur_len, val, position, parent) do

    if (position >= length(list) or position < 0) do
      send(parent, {:response, []})
    else
      #getPossibleNumsArray(List.delete(list, elem), len, cur_len+1, val*10 + elem) ++ doRecurse(list, len, cur_len, val, position+1)
      Task.async(ListLoop, :doRecurse, [list, len, cur_len, val, position+1, self()])
      elem = Enum.at(list, position)
      if elem==0 && val==0 do
        ans=getData()
        send(parent, {:response, ans})
      else
        #ans = getPossibleNumsArray(List.delete(list, elem), len, cur_len+1, val*10 + elem) ++ Task.await(r_task, 100000)
        Task.async(ListLoop, :getPossibleNumsArray, [List.delete(list, elem), len, cur_len+1, val*10 + elem, self()])
        ans = getData() ++ getData()
        send(parent, {:response,ans})
      end
    end
  end

  defp getData() do
    receive do
      {:response, msg} -> msg
    end
  end
end

defmodule FindValidVampires do
  def findVampiresRecurse(list, _target) when length(list) <= 1 do
    []
  end

  def findVampiresRecurse(list, target) do
    val = Enum.at(list, 0)
    residual_list = List.delete(list, val)
    #recTask = Task.async(FindValidVampires, :findVampiresRecurse, [residual_list, target])
    #findVampires(val, residual_list, target) ++ Task.await(recTask)
    findVampires(val, residual_list, target) ++ findVampiresRecurse(residual_list, target)
  end

  def findVampires(_val, residual_list, _target) when length(residual_list)==0 do
    []
  end


  def findVampires(val, residual_list, target) do
    if (length(residual_list)==1) do
      other_num = Enum.at(residual_list, 0)
      if ((val * other_num == target) and !(rem(val,10)==0 and rem(other_num, 10)==0)) do
        digits = Integer.digits(val, 10) ++ Integer.digits(other_num, 10) |> Enum.sort
        tdigit = Integer.digits(target, 10) |> Enum.sort
        if digits === tdigit do
          [[val,other_num]]
        else
          []
        end
      else
        []
      end
    else
      len = length(residual_list)
      mid = 0 + (len>>>1)
      midProd = val*Enum.at(residual_list,mid)
      #IO.puts("findVampires #{inspect self()} #{inspect residual_list , charlists: :as_lists}, #{val}, #{target}")
      #IO.puts("#{midProd}")
      cond do
        midProd < target ->
          if (len != mid+1) do
            #IO.puts("Slice1 #{inspect self()}  #{inspect Enum.slice(residual_list, mid+1, len-mid-1) , charlists: :as_lists}")
            findVampires(val, Enum.slice(residual_list, mid+1, len-mid-1), target)
          else
            []
          end
        midProd > target ->
          if (mid>0) do
            #IO.puts("Slice2 #{inspect self()}  #{inspect Enum.slice(residual_list, 0, mid) , charlists: :as_lists}")
            findVampires(val, Enum.slice(residual_list, 0, mid), target)
          else
            []
          end
        true ->
          #IO.puts("Slice2 #{inspect self()}  #{inspect Enum.slice(residual_list, mid+1, len-mid-1) , charlists: :as_lists}")
          #IO.puts("Slice2 #{inspect self()}  #{inspect Enum.slice(residual_list, 0, mid) , charlists: :as_lists}")
          ans=findVampires(val, Enum.slice(residual_list, mid+1, len-mid-1), target)
          ans++findVampires(val, Enum.slice(residual_list, 0, mid), target)++findVampires(val, [Enum.at(residual_list,mid)], target)
      end
    end
  end
end

defmodule FindVampTCPStruct do
  @derive Jason.Encoder
  defstruct startNum: 0, operationName: "", endNum: 0, parentRef: self()

  def decodeFunction(data) do
    #IO.puts("FindVampTCPStruct #{inspect data}")
    ret = Map.new data, fn({key, value}) ->
      {String.to_atom(key), value}
    end
    struct(FindVampTCPStruct, ret)
  end
end

defmodule App do
  import Bitwise

  @moduledoc """
  Documentation for App.
  """

  def getVampireList(num) do

    #debug info print
    #IO.puts ("Checking if a number is a vampire number. Number is #{num}")
    digits_arr = Integer.digits(num, 10)
    digits = length(digits_arr)

    #vampire numbers are not possible for odd length numbers
    if ((digits&&&1) == 0) do
      digits_arr = Enum.sort(digits_arr)
      ListLoop.getPossibleNumsArray(digits_arr, digits>>>1, 0, 0, self())
      list = receive() |> Enum.uniq |> Enum.sort
      x=FindValidVampires.findVampiresRecurse(list, num)
      #IO.puts("#{num}  #{inspect digits_arr , charlists: :as_lists} #{inspect list , charlists: :as_lists}")

      if length(x)>0 do

        out_list=for item <- x do
          for inner_items <- item do
            Integer.to_string(inner_items)<>" "
          end
        end

        IO.puts("#{num} #{out_list}")
         %{num => x}
      else
        %{}
      end
    else
      %{}
    end
  end

  def getLowerEvenDigitInt(num) do
    digits = Integer.digits(num, 10) |> length

    if ((digits&&&1) == 1) do
      (:math.pow(10, digits-1) - 1) |> round
    else
      num
    end
  end

  def getUpperEvenDigitInt(num) do
    digits = Integer.digits(num, 10) |> length

    if ((digits&&&1) == 1) do
      :math.pow(10, digits) |> round
    else
      num
    end
  end

  defp receive() do
    receive do
      msg ->  msg
    end
  end

  def findVampireNumbers(startNum, endNum, parentRef, state \\[], server_count \\ 0, pos \\0)

  def findVampireNumbers(startNum, endNum, _parentRef, _state, _server_count, _pos) when startNum == endNum do
    getVampireList(endNum)
  end

  def findVampireNumbers(startNum, endNum, _parentRef, _state, _server_count, _pos) when startNum > endNum do
    %{}
  end

  def findVampireNumbers(startNum, endNum, parentRef, state, server_count, pos) do
    IO.puts ("Find vampire numbers called for range " <> Integer.to_string(startNum) <>
             " to " <> Integer.to_string(endNum) <> " Parent Ref: #{inspect parentRef}")

    #To avoid un-necessary processing we can trim the range to a more valid sub-set. Ex 5-555 can be trimmed to 10-99
    #as odd digit ranges are not valid in our scenario
    #Note: these are also very small task and need not be sent to different machines
    startNumTask  = Task.async(App, :getUpperEvenDigitInt, [startNum])
    endNumTask    = Task.async(App, :getLowerEvenDigitInt, [endNum])
    startNum      = Task.await(startNumTask, 10000)
    endNum        = Task.await(endNumTask, 10000)

    if endNum > startNum do
      #if (endNum-startNum < 10) do
      #  for i <- startNum..endNum do
      #    getVampireList(i)
      #  end
      #else

      mid_low = startNum + ((endNum - startNum)>>>1)
      mid_high = mid_low + 1

      #To avoid un-necessary processing we can trim the range to a more valid sub-set. Ex 5-555 can be trimmed to 10-99
      #as odd digit ranges are not valid in our scenario
      #Note: these are also very small task and need not be sent to different machines
      midLowTask = Task.async(App, :getLowerEvenDigitInt, [mid_low])
      midHighTask = Task.async(App, :getUpperEvenDigitInt, [mid_high])
      mid_low = Task.await(midLowTask, 10000)
      mid_high = Task.await(midHighTask, 10000)

      #cond do
      #  server_count == 0 ->
      #    t1=Task.async(App, :findVampireNumbers , [startNum, mid_low, self()])
      #    findVampireNumbers(mid_high, endNum, self()) ++ Task.await(t1, 1000000)
      #  pos < server_count-1 ->

      #end

      if (server_count == 0) do
        IO.puts ("server_count == 0")
        t1=Task.async(App, :findVampireNumbers , [startNum, mid_low, self()])
        findVampireNumbers(mid_high, endNum, self()) ++ Task.await(t1, 1000000)
      end

      #send both request to server
      x=if (pos < server_count-1) do
        IO.puts ("pos < server_count-1)")

        #prepare struct to be sent and serialize the same to JSON
        send_data = %FindVampTCPStruct{operationName: "findVampireNumbers", startNum: startNum, endNum: mid_low, parentRef: "#{inspect self()}"}
        #{:ok, data} = Jason.encode(send_data)

        #send the request to the remote server for processing
        AppTCPServer.sendTCPData(Enum.at(state, pos+1), send_data)

        #prepare struct to be sent and serialize the same to JSON
        send_data = %FindVampTCPStruct{operationName: "findVampireNumbers", startNum: mid_high, endNum: endNum, parentRef: "#{inspect self()}"}
        #{:ok, data} = Jason.encode(send_data)

        #send the request to the remote server for processing
        AppTCPServer.sendTCPData(Enum.at(state, pos+1), send_data)

        #wait for message to be received from both the servers
        IO.puts("waitning for goof )))))))))))))))))))))))))))))))))))))")
        x = Map.merge(receive(), receive())
        IO.puts("hi ans : #{inspect x}")
        x
      end

      #send one request to server and process one by self
      if (pos >= server_count-1) do
        IO.puts("pos >= server_count-1")

        #prepare struct to be sent and serialize the same to JSON
        send_data = %FindVampTCPStruct{operationName: "findVampireNumbers", startNum: mid_high, endNum: endNum, parentRef: "#{inspect self()}"}
        #{:ok, data} = Jason.decode(send_data)

        #send the request to the remote server for processing
        AppTCPServer.sendTCPData(Enum.at(state, rem(pos+1, server_count)), send_data)

        findVampireNumbers(startNum, mid_low, self(), state, server_count) ++ receive()
      end
      x
    else
      findVampireNumbers(startNum, endNum, parentRef, state, server_count, pos)
    end
  end

  def executeTask(data, servers) do
    request = FindVampTCPStruct.decodeFunction(data)
    #IO.inspect (request)
    ans =
    cond do
      request.operationName == "findVampireNumbers"->
        IO.puts("Work")
        t = Task.async(App, :findVampireNumbers, [request.startNum, request.endNum, self(), servers, length(servers)])
        Task.await(t, 10000000)
      true -> []
    end
    ans
  end
end

defmodule AppServerClient do
  use GenServer
  require Logger

  @initial_state %{socket: nil}

  #@impl true
  def start_link do
    GenServer.start_link(__MODULE__, @initial_state, [])
  end

  def put_getPossibleNumsArray(pid, list, len, cur_len, val) do
    GenServer.call(pid, {:getPossibleNumsArray, list, len, cur_len, val}, 1000000)
  end

  # server callbacks

  @impl true
  def init(state) do
    opts = [:binary, active: false]
    {error, socket, _reason} = :gen_tcp.connect('localhost', 52052, opts)
    {error, %{state | socket: socket}}
  end

  @impl true
  def handle_call({:getPossibleNumsArray, list, len, cur_len, val}, _from, state) do
    ListLoop.getPossibleNumsArray(list, len, cur_len, val, self())
    data = receive()
    {:reply, data, state}
  end

  @impl true
  def handle_cast({:getPossibleNumsArray, list, len, cur_len, val}, state) do
    data = ListLoop.getPossibleNumsArray(list, len, cur_len, val, self())
    {:reply, data, state}
  end

  defp receive() do
    receive do
      {:response, msg} -> msg
    end
  end
end
