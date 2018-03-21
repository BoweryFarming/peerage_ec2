defmodule Peerage.Via.Ec2.XmlTest do
  use ExUnit.Case, async: true

  require Record
  Record.defrecord(:xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl"))

  import Peerage.Via.Ec2.Xml

  setup do
    document = File.read!("./test/support/fixtures/fetch_running_services.xml") |> to_charlist
    {:ok, [document: document]}
  end

  describe "all/2" do
    test "returns all nodes for a given path", %{document: document} do
      parsed = document |> parse

      results =
        Enum.map(all(parsed, "//instancesSet/item"), fn node -> xmlElement(node, :name) end)

      assert results == [:item, :item]
    end

    test "returns empty list when path does not match the document", %{document: document} do
      parsed = document |> parse
      results = all(parsed, "//instancesSet/items")
      assert results == []
    end
  end

  describe "first/2" do
    test "returns first node for a given path", %{document: document} do
      parsed = document |> parse
      node = first(parsed, "//instancesSet/item")
      result = xmlElement(node, :name)
      assert result == :item
      address = first(node, "//privateIpAddress") |> text
      assert address == "172.21.22.53"
    end

    test "returns nil when path does not match the document", %{document: document} do
      parsed = document |> parse
      node = first(parsed, "//instancesSet/items")
      assert node == nil
    end
  end

  describe "parse/1" do
    test "parses a charlist", %{document: document} do
      parsed = document |> parse
      assert xmlElement(parsed, :name) == :DescribeInstancesResponse
    end
  end

  describe "text/2" do
    test "returns the text in a given node", %{document: document} do
      parsed = document |> parse
      node = first(parsed, "//instancesSet/item/privateIpAddress")
      result = node |> text
      assert result == "172.21.22.53"
    end

    test "returns nil node does not contain text", %{document: document} do
      parsed = document |> parse
      node = first(parsed, "//instancesSet/item")
      result = node |> text
      assert result == nil
    end

    test "returns nil when node is nil" do
      result = text(nil)
      assert result == nil
    end
  end
end
