defmodule Peerage.Via.Ec2 do
  alias ExAws.EC2
  import SweetXml, only: [sigil_x: 2, xpath: 2, xpath: 3]

  # http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html
  @metadata_api "http://169.254.169.254/latest/meta-data/"

  # http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_InstanceState.html
  @running_state_code 16

  def poll() do
    %{body: doc} =
      EC2.describe_instances(filters: ["tag:#{tag_name(:cluster)}": cluster(), "instance-state-code": @running_state_code])
      |> ExAws.request!(aws_opts())

    services = doc |> xpath(~x"//instancesSet/item"l, host: ~x"./privateIpAddress/text()",
                                                      name: ~x"./tagSet/item[key='#{tag_name(:service)}']/value/text()")

    Enum.map(services, fn(service) ->
      String.to_atom("#{service.name}@" <> to_string(service.host))
    end)
  end

  defp cluster() do
    %{body: doc} =
      EC2.describe_instances(instance_id: instance_id())
      |> ExAws.request!(aws_opts())

    doc
    |> xpath(~x"//tagSet/item[key='#{tag_name(:cluster)}']/value/text()")
    |> to_string
  end

  defp instance_id() do
    case :hackney.request(:get, @metadata_api <> "instance-id", [], "", hackney_opts()) do
      {:ok, 200, _headers, body} -> body
      _ -> raise "metadata api down"
    end
  end

  defp aws_opts() do
    [access_key_id: Application.fetch_env!(:peerage, :aws_access_key_id),
     secret_access_key: Application.fetch_env!(:peerage, :aws_secret_access_key)]
  end

  defp hackney_opts() do
    [{:connect_timeout, 500}, {:recv_timeout, 500}, :with_body]
  end

  defp tag_name(key) do
    Application.fetch_env!(:peerage, :tags)[key]
  end
end
