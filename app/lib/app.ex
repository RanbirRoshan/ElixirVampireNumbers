import Bitwise

defmodule FindPossibleFactors do
  @doc """
  getPossibleNumsArray The code to end the recursion in the function
  """
  def getPossibleNumsArray(_list, len, cur_len, val) when len == cur_len do
    digit_count = Integer.digits(val, 10)
                  |> length

    # consider only the values that are of required length
    if digit_count == len do
      [val]
    else
      []
    end
  end

  def getPossibleNumsArray(list, len, cur_len, val) do
    doRecurse(list, len, cur_len, val, 0)
  end

  def doRecurse(list, _len, _cur_len, _val, position) when position >= length(list) or position < 0 do
    []
  end

  def doRecurse(list, len, cur_len, val, position) do

    elem = Enum.at(list, position)
    ans  = doRecurse(list, len, cur_len, val, position + 1)

    if elem == 0 && val == 0 do
      ans
    else
      getPossibleNumsArray(List.delete(list, elem), len, cur_len + 1, val * 10 + elem) ++ ans
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
  defstruct startNum: 0, operationName: "", endNum: 0, full_range: 0, parentRef: self()

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

  def getVampireList(num, _servers) do

    #debug info print
    digits_arr = Integer.digits(num, 10)
    digits = length(digits_arr)

    #vampire numbers are not possible for odd length numbers
    if ((digits&&&1) == 0) do
      digits_arr = Enum.sort(digits_arr)
      ret= FindPossibleFactors.getPossibleNumsArray(digits_arr, digits>>>1, 0, 0)
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

  def findVampireNumbers(startNum, endNum, parentRef, state \\[], server_count \\ 0, pos \\0, full_range)

  def findVampireNumbers(startNum, endNum, _parentRef, state, _server_count, _pos, _full_range) when startNum == endNum do
    getVampireList(endNum, state)
  end

  def findVampireNumbers(startNum, endNum, _parentRef, _state, _server_count, _pos, _full_range) when startNum > endNum do
    %{}
  end

  def findVampireNumbers(startNum, endNum, parentRef, state, server_count, pos, full_range) do
    #To avoid un-necessary processing we can trim the range to a more valid sub-set. Ex 5-555 can be trimmed to 10-99
    #as odd digit ranges are not valid in our scenario
    #Note: these are also very small task and need not be sent to different machines
    startNum = getUpperEvenDigitInt(startNum)
    endNum = getLowerEvenDigitInt(endNum)
    local_range = Integer.digits(endNum) |> length()
    local_range = :math.pow(10, local_range - 3)
    bucket_size = full_range/local_range |> round()

    if endNum > startNum do

      if (endNum-startNum) > bucket_size do

        mid_low = startNum + ((endNum - startNum)>>>1)
        mid_high = mid_low + 1

        if (server_count == 0) do
          t1=Task.async(App, :findVampireNumbers , [startNum, mid_low, self(), state, server_count, pos, full_range])
          t2=Task.async(App, :findVampireNumbers , [startNum, mid_low, self(), state, server_count, pos, full_range])
          Map.merge(Task.await(t2,100000), Task.await(t1, 1000000))
        end

        #send both request to server
        x=if (pos < server_count-1) do


          #prepare struct to be sent and serialize the same to JSON
          send_data = %FindVampTCPStruct{operationName: "findVampireNumbers", startNum: startNum, endNum: mid_low, full_range: full_range, parentRef: "#{inspect self()}"}
          #{:ok, data} = Jason.encode(send_data)

          #send the request to the remote server for processing
          AppTCPServer.sendTCPData(Enum.at(state, pos+1), send_data)

          #prepare struct to be sent and serialize the same to JSON
          send_data = %FindVampTCPStruct{operationName: "findVampireNumbers", startNum: mid_high, endNum: endNum, full_range: full_range, parentRef: "#{inspect self()}"}
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
          send_data = %FindVampTCPStruct{operationName: "findVampireNumbers", startNum: mid_high, full_range: full_range, endNum: endNum, parentRef: "#{inspect self()}"}

          #send the request to the remote server for processing
          AppTCPServer.sendTCPData(Enum.at(state, rem(pos+1, server_count)), send_data)

          t1=Task.async(App, :findVampireNumbers , [startNum, mid_low, self(), state, server_count, 0, full_range])
          Map.merge(Task.await(t1, 1000000), receive())
        else
          x
        end
        x
      else
        res =
          for i <- startNum..endNum do
            getVampireList(i, state)
          end
        Enum.reduce(res, fn x, acc ->
          Map.merge(x, acc, fn _key, map1, map2 ->
            for {k, v1} <- map1, into: %{}, do: {k, v1 + map2[k]}
          end)
        end)
      end
    else
      findVampireNumbers(startNum, endNum, parentRef, state, server_count, pos, full_range)
    end
  end

  def executeTask(data, servers) do
    request = FindVampTCPStruct.decodeFunction(data)
    #IO.inspect (request)
    ans =
    cond do
      request.operationName == "findVampireNumbers"->
        Logger.info("Request received : findVampireNumbers for range (#{request.startNum}, #{request.endNum})")
        t = Task.async(App, :findVampireNumbers, [request.startNum, request.endNum, self(), servers, length(servers), request.full_range])
        Task.await(t, 10000000)
      true -> []
    end
    ans
  end
end
