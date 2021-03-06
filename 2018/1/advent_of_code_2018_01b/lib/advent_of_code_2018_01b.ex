defmodule AdventOfCode201801b do
  @moduledoc """
    Author: Matthew Reishus
    Date: 2018-12-01
    Purpose: Advent Of Code 2018, Day 1, Puzzle 2

    Program reads a text file in "input.txt" comprised of lines like
    "+5", "-100" or "+89". All lines begin with either "-" or "+".

    The program returns the first sum that is reached twice.  It may have to
    loop over the entire list.
  """

  @doc """
    calculate_tally: Meant to be passed to a Enum.reduce call. This uses a map called "tally"
    as the accumulator, which contains both the current sum and the previous sums we have seen.

    Param 1: string_with_operator (string) formatted like "+1" or "-10".  Sign is mandatory.
    Param 2: tally (map) with these keys:
      sum (integer) Rolling sum.
      seen_map (map -> %{integer: integer}) Which sums we have seen and how many times.
      seen_multiple (list of integers) All sums seen multiple times, the most recent at end of the list.
  """
  def calculate_tally(num, tally) do
    sum = num + tally.sum

    sum_seen_count = 1 + Map.get(tally.seen_map, sum, 0)
    seen_map = Map.put(tally.seen_map, sum, sum_seen_count)

    seen_multiple = case sum_seen_count do
      n when n > 1 -> tally.seen_multiple ++ [sum]
      _ -> tally.seen_multiple
    end

    %{ tally | sum: sum, seen_map: seen_map, seen_multiple: seen_multiple }
  end

  @doc """
    print_first_repeated_sum: Reads all lines in input.txt, summing them, and finds the
    first repeated sum, repeating the file as many times as possible.
  """
  def print_first_repeated_sum() do
    file_name = Path.expand("./", __DIR__) |> Path.join("input.txt")
    {:ok, contents} = File.read(file_name)
    list = contents
      |> String.split("\n", trim: true)
      |> Enum.map(fn x -> String.to_integer(x) end)
    f = first_repeated_sum(list)
    IO.inspect f
  end

  @doc """
    first_repeated_sum: Given a list of strings like "+1", "-5", "+20", find the first repeated sum,
    repeating the entire list as many times as needed.  May run forever.
  """
  def first_repeated_sum(list) do
    tally = %{
      sum: 0,
      seen_map: %{0 => 1},
      seen_multiple: [],
    }
    first_repeated_sum(list, tally)
  end

  defp first_repeated_sum(list, tally) do
    tally = list |> Enum.reduce(tally, &AdventOfCode201801b.calculate_tally/2)

    case length(tally.seen_multiple) do
      0 -> first_repeated_sum(list, tally)
      _ -> List.first(tally.seen_multiple)
    end
  end
end

defmodule Benchmark do
  def measure(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000)
  end
end

#IO.inspect Benchmark.measure(fn -> AdventOfCode201801b.print_first_repeated_sum() end)
