defmodule Peerage.Via.Ec2 do
  @behaviour Peerage.Provider
  require Logger

  alias ExAws.EC2
  import SweetXml, only: [sigil_x: 2, xpath: 2, xpath: 3]

  @metadata_api "http://169.254.169.254/latest/meta-data/"
  @running_state_code 16

  def poll() do
    %{body: doc} =
      EC2.describe_instances(filters: ["tag:cluster": cluster_name(), "instance-state-code": @running_state_code])
      |> ExAws.request!

    services = doc |> xpath(~x"//instancesSet/item"l, host: ~x"./privateIpAddress/text()",
                                                      name: ~x"./tagSet/item[key='service']/value/text()")

    Enum.map(services, fn(service) ->
      String.to_atom("#{service.name}@" <> to_string(service.host))
    end)
  end

  defp cluster_name() do
    %{body: doc} =
      EC2.describe_instances(instance_id: local_instance_id())
      |> ExAws.request!

    doc
    |> xpath(~x"//tagSet/item[key='cluster']/value/text()")
    |> to_string
  end

  defp local_instance_id() do
    case :hackney.request(:get, @metadata_api <> "instance-id", [], "", [:with_body]) do
      {:ok, 200, _headers, body} -> body
    end
  end
end
