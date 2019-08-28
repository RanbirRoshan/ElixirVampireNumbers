defmodule ListLoop do
  @doc """
  getPossibleNumsArray The code to end the recursion in the function
  """
  def getPossibleNumsArray(_list, len, cur_len, val) when len==cur_len do
    digit_count = Integer.digits(val, 10) |> length

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
    r_task = Task.async(ListLoop, :doRecurse, [list, len, cur_len, val, position+1])
    getPossibleNumsArray(List.delete(list, elem), len, cur_len+1, val*10 + elem) ++ Task.await(r_task)
  end
end
import Bitwise
defmodule FindValidVampires do
  def findVampiresRecurse(list, _target) when length(list) <= 1 do
    []
  end

  def findVampiresRecurse(list, target) do
    val = Enum.at(list, 0)
    residual_list = List.delete(list, val)
    recTask = Task.async(FindValidVampires, :findVampiresRecurse, [residual_list, target])
    findVampires(val, residual_list, target) ++ Task.await(recTask)
  end

  def findVampires(_val, residual_list, target) when length(residual_list)==0 do
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
      list = ListLoop.getPossibleNumsArray(digits_arr, digits>>>1, 0, 0) |> Enum.uniq |> Enum.sort
      x=FindValidVampires.findVampiresRecurse(list, num)
      #IO.puts("#{num}  #{inspect digits_arr , charlists: :as_lists} #{inspect list , charlists: :as_lists}")
      if length(x)>0 do
        IO.puts("#{num}  #{inspect x, charlists: :as_lists}")
      end
    else
      []
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

  @doc """
  Execute
  """
  def findVampireNumbers(startNum, endNum, parentRef) do
     #when is_integer(StartNum) and is_integer(EndNum) and is_pid(ParentRef) do

    #printing info for debug purposes
    if (startNum == endNum) do
      getVampireList(endNum)
    else
      #IO.puts ("Find vampire numbers called for range " <> Integer.to_string(startNum) <>
      #         " to " <> Integer.to_string(endNum) <> " Parent Ref: #{inspect parentRef}")

      startNumTask = Task.async(App, :getUpperEvenDigitInt, [startNum])
      endNumTask = Task.async(App, :getLowerEvenDigitInt, [endNum])
      startNum = Task.await(startNumTask)
      endNum = Task.await(endNumTask)

      if endNum > startNum do

        mid_low = startNum + ((endNum - startNum)>>>1)
        mid_high = mid_low + 1

        midLowTask = Task.async(App, :getLowerEvenDigitInt, [mid_low])
        midHighTask = Task.async(App, :getUpperEvenDigitInt, [mid_high])
        mid_low = Task.await(midLowTask)
        mid_high = Task.await(midHighTask)
        #mid_low = getLowerEvenDigitInt(mid_low)
        #mid_high = getUpperEvenDigitInt(mid_high)
        #IO.puts("#{startNum} #{mid_low} #{mid_high} #{endNum}")
        #running the same over interval now
        t1=Task.async(App, :findVampireNumbers , [startNum, mid_low, self()])
        t2=Task.async(App, :findVampireNumbers , [mid_high, endNum, self()])
        Task.await(t1)
        Task.await(t2)

      end

      if endNum==startNum do
        getVampireList(endNum)
      end

    end

  end

end
