defmodule Peerage.Via.Ec2Test do
  use ExUnit.Case, async: false

  import Mock
  alias Peerage.Via.Ec2
  alias Peerage.Via.Ec2.SignedUrl.RequestTime

  @now ~N[1980-10-17 01:23:45]
  @instance_id 'my-instance-id'

  setup do
    metadata_api_url = 'http://169.254.169.254/latest/meta-data/instance-id'

    cluster_name_url =
      'https://ec2.amazonaws.com/?Action=DescribeInstances&Filter.1.Name=instance-id&Filter.1.Value.1=my-instance-id&Version=2016-11-15&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=example%2F19801017%2Fus-east-1%2Fec2%2Faws4_request&X-Amz-Date=19801017T012345Z&X-Amz-Expires=86400&X-Amz-Signature=fd6f96b448eca8bc766772556a99a83f4515a2486ee2946d0e1ac9c49f6ae672&X-Amz-SignedHeaders=host'

    running_services_url =
      'https://ec2.amazonaws.com/?Action=DescribeInstances&Filter.1.Name=instance-state-code&Filter.1.Value.1=16&Filter.2.Name=tag%3Acluster&Filter.2.Value.1=staging&Version=2016-11-15&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=example%2F19801017%2Fus-east-1%2Fec2%2Faws4_request&X-Amz-Date=19801017T012345Z&X-Amz-Expires=86400&X-Amz-Signature=2593cc39b442ec5bf04bc91010a4a809d3b04b5ed772a427c44c1efcac3e094f&X-Amz-SignedHeaders=host'

    cluster_name_response =
      File.read!("./test/support/fixtures/fetch_cluster_name.xml") |> to_charlist

    running_services_response =
      File.read!("./test/support/fixtures/fetch_running_services.xml") |> to_charlist

    {:ok,
     metadata_api_url: metadata_api_url,
     cluster_name_url: cluster_name_url,
     running_services_url: running_services_url,
     cluster_name_response: cluster_name_response,
     running_services_response: running_services_response}
  end

  describe "poll/0" do
    test "returns a list of instances from EC2", %{
      metadata_api_url: metadata_api_url,
      cluster_name_url: cluster_name_url,
      running_services_url: running_services_url,
      cluster_name_response: cluster_name_response,
      running_services_response: running_services_response
    } do
      with_mocks([
        {RequestTime, [], [now: fn -> @now end]},
        {:httpc, [],
         [
           request: fn :get, {url, _}, _, _ ->
             case url do
               ^metadata_api_url -> successful_response(@instance_id)
               ^cluster_name_url -> successful_response(cluster_name_response)
               ^running_services_url -> successful_response(running_services_response)
             end
           end
         ]}
      ]) do
        assert Ec2.poll() == [:"gardiner@172.21.22.53", :"falkner@170.31.21.52"]
      end
    end

    test "returns an empty list when metadata request fails", %{
      metadata_api_url: metadata_api_url
    } do
      with_mocks([
        {RequestTime, [], [now: fn -> @now end]},
        {:httpc, [], [request: fn :get, {^metadata_api_url, _}, _, _ -> failed_response() end]}
      ]) do
        assert Ec2.poll() == []
      end
    end

    test "returns an empty list when cluster name request fails", %{
      metadata_api_url: metadata_api_url,
      cluster_name_url: cluster_name_url
    } do
      with_mocks([
        {RequestTime, [], [now: fn -> @now end]},
        {:httpc, [],
         [
           request: fn :get, {url, _}, _, _ ->
             case url do
               ^metadata_api_url -> successful_response(@instance_id)
               ^cluster_name_url -> failed_response()
             end
           end
         ]}
      ]) do
        assert Ec2.poll() == []
      end
    end

    test "returns an empty list when running services request fails", %{
      metadata_api_url: metadata_api_url,
      cluster_name_url: cluster_name_url,
      running_services_url: running_services_url,
      cluster_name_response: cluster_name_response
    } do
      with_mocks([
        {RequestTime, [], [now: fn -> @now end]},
        {:httpc, [],
         [
           request: fn :get, {url, _}, _, _ ->
             case url do
               ^metadata_api_url -> successful_response(@instance_id)
               ^cluster_name_url -> successful_response(cluster_name_response)
               ^running_services_url -> failed_response()
             end
           end
         ]}
      ]) do
        assert Ec2.poll() == []
      end
    end
  end

  defp successful_response(body), do: httpc_response(200, body)
  defp failed_response(), do: httpc_response(403)

  defp httpc_response(code, body \\ ""), do: {:ok, {{"", code, ""}, %{}, body}}
end
