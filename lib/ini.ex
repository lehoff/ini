defmodule Ini do

  def decode(data) do
    data
    |> split
    |> tokenise
    |> build
    |> return
  end

  def split(data) do
    data
    |> String.split(~r/[\r\n]+/)
  end

  def return({_, output}) do
    output
  end

  def build(tokens) do
    tokens
    |> Enum.reduce({nil, %{}}, &add_token/2)
  end

  defp add_token({:section, name}, {_, output}) do
    {name, output}
  end
  defp add_token({:assign, key, value}, {path, output}) do
    {path, update_in(output, path, key, value)}
  end
  defp add_token({:array, key, value}, {path, output}) do
    {path, update_array_in(output, path, key, value)}
  end

  def tokenise(lines) do
    lines |> filter_comments_empty |> Enum.map(&tokenise_line/1)
  end
  defp filter_comments_empty(lines) do
    Enum.filter(lines, fn(line) ->
      !Regex.match?(~r/^\s*[;]/, line) and line != ""
    end)
  end
  def tokenise_line(line) do
    cond do
      section?(line) ->
        section(line)
      array_assign?(line) ->
        array_assign(line)
      assign?(line) ->
        assign(line)
      true ->
        IO.puts("Failed to tokenise: #{ inspect line }")
    end
  end

  def section(line) do
    caps = Regex.named_captures(section_regex(), line)
    {:section, get_trim(caps, "section")}
  end
  def array_assign(line) do
    caps = Regex.named_captures(array_assign_regex(), line)
    {:array, get_trim(caps, "array"), get_trim(caps, "value")}
  end
  def assign(line) do
    caps = Regex.named_captures(assign_regex(), line)
    {:assign, get_trim(caps, "key"), get_trim(caps, "value")}
  end

  def get_trim(map, key) do
    Map.get(map, key) |> String.trim
  end

  defp section?(line) do
    Regex.match?(section_regex, line)
  end
  defp array_assign?(line) do
    Regex.match?(array_assign_regex, line)
  end
  defp assign?(line) do
    Regex.match?(assign_regex, line)
  end

  defp section_regex() do
    ~r/^\[\s*(?<section>[^\]]*)\s*\]$/i
  end
  defp array_assign_regex() do
    ~r/^\s*(?<array>[^\[]+)\[\]\s*=\s*(?<value>.*)\s*$/i
  end
  defp assign_regex() do
    ~r/^\s*(?<key>[^=\[]+)\s*=\s*(?<value>.*)\s*$/i
  end

  # update_in(%{}, nil, key, value) -> %{key => value}
  # update_in(%{}, :foo, key, value) -> %{ foo => %{ key => value }}
  defp update_in(map, nil, key, value) do
    Map.put(map, key, value)
  end
  defp update_in(map, path, key, value) do
    Map.update(map, path, %{key => value}, fn(section) ->
      Map.put(section, key, value)
    end)
  end

  defp update_array_in(map, nil, key, value) do
    Map.update(map, key, [value], fn(current) ->
      current ++ [value]
    end)
  end
  defp update_array_in(map, path, key, value) do
    Map.update(map, path, %{key => [value]}, fn(section) ->
      Map.update(section, key, [value], fn(current) ->
        current ++ [value]
      end)
    end)
  end

end
