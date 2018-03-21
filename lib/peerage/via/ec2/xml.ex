defmodule Peerage.Via.Ec2.Xml do
  @moduledoc """
  Xml is a thin wrapper around xmerl providing helper functions
  for parsing and retrieving data from XML documents.

  http://erlang.org/doc/man/xmerl.html
  """
  require Record
  Record.defrecord(:xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl"))

  @doc """
  Parse a charlist containing an XML document using xmerl_scan.
  """
  def parse(xml_charlist, options \\ [quiet: true]) do
    {doc, []} = :xmerl_scan.string(xml_charlist, options)
    doc
  end

  @doc """
  Select all nodes matching a given path in an XML document.
  """
  def all(node, path) do
    for child_element <- xpath(node, path) do
      child_element
    end
  end

  @doc """
  Select the first node matching a path in an XML document.
  """
  def first(node, path), do: node |> xpath(path) |> take_one
  defp take_one([head | _]), do: head
  defp take_one(_), do: nil

  @doc """
  Extract the text from a node in an XML document.
  """
  def text(node), do: node |> xpath('./text()') |> extract_text
  defp extract_text([xmlText(value: value)]), do: List.to_string(value)
  defp extract_text(_x), do: nil

  defp xpath(nil, _), do: []
  defp xpath(node, path), do: :xmerl_xpath.string(to_charlist(path), node)
end
