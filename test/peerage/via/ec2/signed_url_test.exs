defmodule Peerage.Via.Ec2.SignedUrlTest do
  use ExUnit.Case, async: false

  import Mock

  alias Peerage.Via.Ec2.SignedUrl

  describe "build/1" do
    test "returns a signed URL with the expected signature" do
      with_mock SignedUrl.RequestTime, now: fn -> ~N[1980-10-17 01:23:45] end do
        signed =
          "https://ec2.amazonaws.com/?Action=DescribeInstances&Version=2016-11-15"
          |> SignedUrl.build()
          |> URI.parse()

        assert signed.host == "ec2.amazonaws.com"
        assert signed.scheme == "https"
        assert signed.path == "/"

        expected_params = [
          {"Action", "DescribeInstances"},
          {"Version", "2016-11-15"},
          {"X-Amz-Algorithm", "AWS4-HMAC-SHA256"},
          {"X-Amz-Credential", "example/19801017/us-east-1/ec2/aws4_request"},
          {"X-Amz-Date", "19801017T012345Z"},
          {"X-Amz-Expires", "86400"},
          {"X-Amz-Signature", "a727045c681d8e4cfd883259dc2879e5a73df65fd4fabf51176986ce8cf18a00"},
          {"X-Amz-SignedHeaders", "host"}
        ]

        signed_params =
          signed.query
          |> URI.query_decoder()
          |> Enum.to_list()

        assert signed_params == expected_params
      end
    end
  end

  describe "RequestTime.now/0" do
    test "a current naive date time" do
      expected = DateTime.utc_now() |> DateTime.to_naive()
      now = SignedUrl.RequestTime.now()
      assert now.__struct__ == NaiveDateTime
      diff = NaiveDateTime.diff(now, expected)
      assert diff < 10
    end
  end
end
