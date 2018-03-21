defmodule Peerage.Via.Ec2 do
  @moduledoc """
  A Peerage provider for easy clustering on AWS EC2 and Elastic Beanstalk.
  """
  @behaviour Peerage.Provider

  alias Peerage.Via.Ec2.{SignedUrl, Xml}

  @doc """
  Periodically polls the metadata and EC2 API's for other nodes in the same "cluster."
  """
  def poll() do
    fetch_instance_id()
    |> fetch_cluster_name()
    |> fetch_running_services()
    |> format_services_list()
  end

  defp fetch_instance_id() do
    # EC2 provides an instance metadata API endpoint. We'll perform
    # a request to determine the ID of the running instance.
    #
    # AWS Documentation: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html
    metadata_api = 'http://169.254.169.254/latest/meta-data/instance-id'

    case request(metadata_api) do
      {:ok, {{_, 200, _}, _headers, body}} -> to_string(body)
      _ -> :error
    end
  end

  defp fetch_cluster_name(:error), do: :error

  defp fetch_cluster_name(instance_id) do
    # Having retrieved the instance_id of the current EC2 instance,
    # we'll peform a signed/authenticated request to Amazon's EC2
    # DescribeInstances API to retrieve the name of the `cluster`
    # of instances we've tagged.
    request_uri =
      %{}
      |> Map.put("Filter.1.Name", "instance-id")
      |> Map.put("Filter.1.Value.1", instance_id)
      |> describe_endpoint()
      |> SignedUrl.build()
      |> to_charlist()

    case request(request_uri) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        body
        |> Xml.parse()
        |> Xml.first("//tagSet/item[key='#{tag_name(:cluster)}']/value")
        |> Xml.text()

      _ ->
        :error
    end
  end

  defp fetch_running_services(:error), do: :error

  defp fetch_running_services(cluster_name) do
    # Having retrieved the cluster_name, we'll peform a
    # signed/authenticated request to Amazon's EC2
    # DescribeInstances API to retrieve all of the
    # running services in that cluster.
    #
    # Note that, an InstanceState code of 16 represents
    # a running EC2 service.
    #
    # AWS Documentation: http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_InstanceState.html
    request_uri =
      %{}
      |> Map.put("Filter.1.Name", "instance-state-code")
      |> Map.put("Filter.1.Value.1", "16")
      |> Map.put("Filter.2.Name", "tag:#{tag_name(:cluster)}")
      |> Map.put("Filter.2.Value.1", cluster_name)
      |> describe_endpoint()
      |> SignedUrl.build()
      |> to_charlist()

    case request(request_uri) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        instances = Xml.parse(body)

        Enum.map(Xml.all(instances, "//instancesSet/item"), fn node ->
          host = Xml.first(node, "//privateIpAddress") |> Xml.text()
          service = Xml.first(node, "//tagSet/item[key='service']/value") |> Xml.text()
          %{host: host, name: service}
        end)

      _ ->
        :error
    end
  end

  defp format_services_list(:error), do: []

  defp format_services_list(services) do
    Enum.map(services, fn service ->
      String.to_atom("#{service.name}@" <> to_string(service.host))
    end)
  end

  defp describe_endpoint(filters) do
    query_string =
      filters
      |> Map.put("Action", "DescribeInstances")
      |> Map.put("Version", "2016-11-15")
      |> URI.encode_query()

    "https://ec2.amazonaws.com/?" <> query_string
  end

  defp request(uri), do: :httpc.request(:get, {uri, []}, [timeout: 1000], [])
  defp tag_name(key), do: Application.fetch_env!(:peerage_ec2, :tags)[key]
end
