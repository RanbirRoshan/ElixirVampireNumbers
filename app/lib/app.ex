import Bitwise

defmodule ListLoop do
  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start(initial_state) do
    #Logger.info("Starting server with an inital state: #{inspect initial_state}")
    GenServer.start(__MODULE__, initial_state, [])
  end

  def getPossibleNumsArray(list, len, cur_len, val, parent, servers, pos \\ 0)
  def getPossibleNumsArray(_list, len, cur_len, val, parent, _servers, _pos) when len==cur_len do
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

  def getPossibleNumsArray(list, len, cur_len, val, parent, servers, pos) do
    #IO.puts("called #{inspect parent} is parent of #{inspect self()}")
    doRecurse(list, len, cur_len, val, 0, parent, servers,  pos)
  end

  def doRecurse(list, len, cur_len, val, position, parent, servers, pos) do
    #IO.puts("#{inspect self()} #{inspect parent}")
    if (position >= length(list) or position < 0) do
      send(parent, {:response, []})
    else
      elem = Enum.at(list, position)

      Task.async(ListLoop, :doRecurse, [list, len, cur_len, val, position+1, self(), servers, pos+1])

      if elem==0 && val==0 do
        ans=getData()
        send(parent, {:response, ans})
      else
        {:ok, pid} = ListLoop.start([])
        GenServer.cast(pid, {:getPossibleNumsArray, List.delete(list, elem), len, cur_len+1, val*10 + elem, self(), servers, pos+2})

        #Task.async(ListLoop, :getPossibleNumsArray, [List.delete(list, elem), len, cur_len+1, val*10 + elem, self(), servers, pos+2])
        ans = getData() ++ getData()
        send(parent, {:response,ans})
      end
    end
  end

  @impl true
  def handle_cast({:getPossibleNumsArray, digits_arr, len, cur_len, val, parent, servers, pos}, state) do
    spawn fn ->  ListLoop.getPossibleNumsArray(digits_arr, len, cur_len, val, parent, servers, pos) end
    {:noreply, state}
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
    val           = Enum.at(list, 0)
    residual_list = List.delete(list, val)
    ans           = findVampiresRecurse(residual_list, target)

    findVampires(val, residual_list, target) ++ ans
  end

  def findVampires(_val, residual_list, _target) when length(residual_list)==0 do
    []
  end


  def findVampires(val, residual_list, target) do
    if (length(residual_list) == 1) do
      other_num = Enum.at(residual_list, 0)
      if ((val * other_num == target) and !(rem(val, 10) == 0 and rem(other_num, 10) == 0)) do
        digits = Integer.digits(val, 10) ++ Integer.digits(other_num, 10)
                 |> Enum.sort
        tdigit = Integer.digits(target, 10)
                 |> Enum.sort
        if digits === tdigit do
          [[val, other_num]]
        else
          []
        end
      else
        []
      end
    else
      len = length(residual_list)
      mid = 0 + (len >>> 1)
      other = Enum.at(residual_list, mid)
      midProd = val * other

      cond do
        midProd < target ->
          if (len != mid + 1) do
            findVampires(val, Enum.slice(residual_list, mid + 1, len - mid - 1), target)
          else
            []
          end

        midProd > target ->
          if (mid > 0) do
            findVampires(val, Enum.slice(residual_list, 0, mid), target)
          else
            []
          end

        true ->
          if (!(rem(val, 10) == 0 and rem(other, 10) == 0)) do
            digits = Integer.digits(val, 10) ++ Integer.digits(other, 10) |> Enum.sort
            tdigit = Integer.digits(target, 10) |> Enum.sort

            if digits === tdigit do
              [[val, other]] ++ findVampires(val, [Enum.at(residual_list, mid)], target)
            else
              findVampires(val, [Enum.at(residual_list, mid)], target)
            end

          else
            findVampires(val, [Enum.at(residual_list, mid)], target)
          end
      end
    end
  end
end

defmodule FindVampTCPStruct do
  @derive Jason.Encoder
  defstruct startNum: 0, operationName: "", endNum: 0, parentRef: self()

  def decodeFunction(data) do
    ret = Map.new data, fn({key, value}) ->
      {String.to_atom(key), value}
    end
    struct(FindVampTCPStruct, ret)
  end
end

defmodule App do
  import Bitwise
  require Logger

  @moduledoc """
  Documentation for App.
  """

  def getVampireList(num, servers) do

    #debug info print
    digits_arr = Integer.digits(num, 10)
    digits = length(digits_arr)

    #vampire numbers are not possible for odd length numbers
    if ((digits&&&1) == 0) do
      digits_arr = Enum.sort(digits_arr)
      {:ok, pid} = ListLoop.start([])
      GenServer.cast(pid, {:getPossibleNumsArray, digits_arr, digits>>>1, 0, 0, self(), servers, 0})
      ret= receive()
      list = ret |> Enum.uniq |> Enum.sort
      x=FindValidVampires.findVampiresRecurse(list, num)

      if length(x)>0 do
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
      {_a, {:response, msg}} -> msg
      {:response, msg} -> msg
      msg ->  msg
    end
  end

  def findVampireNumbers(startNum, endNum, parentRef, state \\[], server_count \\ 0, pos \\0)

  def findVampireNumbers(startNum, endNum, _parentRef, state, _server_count, _pos) when startNum == endNum do
    getVampireList(endNum, state)
  end

  def findVampireNumbers(startNum, endNum, _parentRef, _state, _server_count, _pos) when startNum > endNum do
    %{}
  end

  def findVampireNumbers(startNum, endNum, parentRef, state, server_count, pos) do
    #To avoid un-necessary processing we can trim the range to a more valid sub-set. Ex 5-555 can be trimmed to 10-99
    #as odd digit ranges are not valid in our scenario
    #Note: these are also very small task and need not be sent to different machines
    startNum = getUpperEvenDigitInt(startNum)
    endNum = getLowerEvenDigitInt(endNum)

    if endNum > startNum do

      mid_low = startNum + ((endNum - startNum)>>>1)
      mid_high = mid_low + 1

      if (server_count == 0) do
        t1=Task.async(App, :findVampireNumbers , [startNum, mid_low, self()])
        t2=Task.async(App, :findVampireNumbers , [startNum, mid_low, self()])
        Map.merge(Task.await(t2,100000), Task.await(t1, 1000000))
      end

      #send both request to server
      x=if (pos < server_count-1) do


        #prepare struct to be sent and serialize the same to JSON
        send_data = %FindVampTCPStruct{operationName: "findVampireNumbers", startNum: startNum, endNum: mid_low, parentRef: "#{inspect self()}"}
        #{:ok, data} = Jason.encode(send_data)

        #send the request to the remote server for processing
        AppTCPServer.sendTCPData(Enum.at(state, pos+1), send_data)

        #prepare struct to be sent and serialize the same to JSON
        send_data = %FindVampTCPStruct{operationName: "findVampireNumbers", startNum: mid_high, endNum: endNum, parentRef: "#{inspect self()}"}
        #{:ok, data} = Jason.encode(send_data)

        #send the request to the remote server for processing
        AppTCPServer.sendTCPData(Enum.at(state, pos), send_data)

        #wait for message to be received from both the servers
        Map.merge(receive(), receive())

      else
        %{}
      end

      #send one request to server and process one by self
      x =
      if (pos >= server_count-1) do

        #prepare struct to be sent and serialize the same to JSON
        send_data = %FindVampTCPStruct{operationName: "findVampireNumbers", startNum: mid_high, endNum: endNum, parentRef: "#{inspect self()}"}

        #send the request to the remote server for processing
        AppTCPServer.sendTCPData(Enum.at(state, rem(pos+1, server_count)), send_data)

        t1=Task.async(App, :findVampireNumbers , [startNum, mid_low, self(), state, server_count, 0])
        Map.merge(Task.await(t1, 1000000), receive())
      else
        x
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
        Logger.info("Request received : findVampireNumbers for range (#{request.startNum}, #{request.endNum})")
        t = Task.async(App, :findVampireNumbers, [request.startNum, request.endNum, self(), servers, length(servers)])
        Task.await(t, 10000000)
      true -> []
    end
    ans
  end
end
