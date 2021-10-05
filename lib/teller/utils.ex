defmodule Teller.Utils do
  def generate_int(seed, max) when is_integer(seed) do
    generate_int(Integer.to_string(seed), max)
  end

  def generate_int(seed, max) do
    :crypto.hash(:sha, seed)
    |> Base.encode16()
    |> Integer.parse(16)
    |> then(fn {int, _} -> Integer.mod(int, max) end)
  end

  def last_n_letters(string, n) do
    string
    |> String.to_charlist()
    |> Enum.reverse()
    |> Enum.take(n)
    |> Enum.reverse()
    |> to_string()
  end

  def get_at(list, index) do
    get_stream_from(list, index)
    |> Enum.at(0)
  end

  def get_stream_from(list, index) do
    to_drop = Integer.mod(index, length(list))

    Stream.cycle(list)
    |> Stream.drop(to_drop)
  end

  def floor_and_mod(dividend, divisor) do
    {Integer.floor_div(dividend, divisor), Integer.mod(dividend, divisor)}
  end

  def take_from_stream(stream, number) do
    {Enum.take(stream, number), Stream.drop(stream, number)}
  end
end
