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

import Bitwise

defmodule FindVampireFangs do

  def findVampiresRecurse(list, _target) when length(list) <= 1 do
    []
  end

  def findVampiresRecurse(list, target) do

    val           = Enum.at(list, 0)
    residual_list = List.delete(list, val)
    ans           = findVampiresRecurse(residual_list, target)

    findVampires(val, residual_list, target) ++ ans
  end

  def findVampires(_val, residual_list, _target) when length(residual_list) == 0 do
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
          #IO.puts("Slice2 #{inspect self()}  #{inspect Enum.slice(residual_list, mid+1, len-mid-1) , charlists: :as_lists}")
          #IO.puts("Slice2 #{inspect self()}  #{inspect Enum.slice(residual_list, 0, mid) , charlists: :as_lists}")
          #ans = findVampires(val, Enum.slice(residual_list, mid + 1, len - mid - 1), target)
          #ans ++ findVampires(val, Enum.slice(residual_list, 0, mid), target) ++ findVampires(val, [Enum.at(residual_list, mid)], target)
          if (!(rem(val, 10) == 0 and rem(other, 10) == 0)) do
            digits = Integer.digits(val, 10) ++ Integer.digits(other, 10)
                     |> Enum.sort
            tdigit = Integer.digits(target, 10)
                     |> Enum.sort
            if digits === tdigit do
              [[val, other]] ++ findVampires(val, [Enum.at(residual_list, mid)], target)
            else
              findVampires(val, [Enum.at(residual_list, mid)], target)
            end
          else
            findVampires(val, [Enum.at(residual_list, mid)], target)
          end
          #findVampires(val, [Enum.at(residual_list, mid)], target) ++ [[val, Enum.at(residual_list, mid)]]
      end
    end
  end
end

defmodule FindAllVampires do
  import Bitwise
  use GenServer

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_cast({:findVampireNumbers, startNum, endNum, parentRef, full_range}, _state) do
    findVampireNumbers(startNum, endNum, parentRef, full_range)
    {:noreply, :ok}
  end

  defp receiveAsyncMsgs() do
    receive do
      {_ref, msg} -> msg
      msg -> msg
    end
  end


  def getVampireList(num) do

    digits_arr = Integer.digits(num, 10)
    digits = length(digits_arr)

    #vampire numbers are not possible for odd length numbers
    if ((digits &&& 1) == 0) do

      digits_arr = Enum.sort(digits_arr)

      list = FindPossibleFactors.getPossibleNumsArray(digits_arr, digits >>> 1, 0, 0)
             |> Enum.uniq
             |> Enum.sort

      x = FindVampireFangs.findVampiresRecurse(list, num)

      if length(x) > 0 do
        %{num => x}
      else
        %{}
      end

    else
      %{}
    end
  end

  def getLowerEvenDigitInt(num) do
    digits = Integer.digits(num, 10)
             |> length

    if ((digits &&& 1) == 1) do
      (:math.pow(10, digits - 1) - 1)
      |> round
    else
      num
    end
  end

  def getUpperEvenDigitInt(num) do
    digits = Integer.digits(num, 10)
             |> length

    if ((digits &&& 1) == 1) do
      :math.pow(10, digits)
      |> round
    else
      num
    end
  end

  def findVampireNumbers(startNum, endNum, parentRef, full_range) do

    if (startNum == endNum) do
      send(parentRef, getVampireList(endNum))
    else

      startNum = getUpperEvenDigitInt(startNum)
      endNum = getLowerEvenDigitInt(endNum)

      local_range = Integer.digits(endNum) |> length()
      local_range = :math.pow(10, local_range - 3)
      bucket_size = full_range/local_range |> round()
      #IO.puts("#{startNum} #{endNum} #{local_range} #{full_range} #{bucket_size}")
      ans =
        if endNum>startNum do

          if (endNum-startNum) > bucket_size do
            mid_low  = startNum + ((endNum - startNum) >>> 1)
            mid_high = mid_low + 1

            {:ok, pid} = GenServer.start(FindAllVampires, [])
            GenServer.cast(pid, {:findVampireNumbers, startNum, mid_low, self(), full_range})

            findVampireNumbers(mid_high, endNum, self(), full_range)
            ans = receiveAsyncMsgs()
            ans2 = receiveAsyncMsgs() #Task.await(t1, 10000000)

            Map.merge(ans, ans2)
          else
            res =
            for i <- startNum..endNum do
              getVampireList(i)
            end
            Enum.reduce(res, fn x, acc ->
                 Map.merge(x, acc, fn _key, map1, map2 ->
                   for {k, v1} <- map1, into: %{}, do: {k, v1 + map2[k]}
                 end)
               end)
          end
          #Task.await(t2)
        else
          %{}
        end

        if endNum == startNum do
          send(parentRef, getVampireList(endNum))
        else
          send(parentRef, ans)
        end
    end
  end
end
