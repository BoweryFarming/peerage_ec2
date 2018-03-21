defmodule Peerage.Via.Ec2.SignedUrl do
  @moduledoc """
  SignedUrl provides a helper function to generate signed urls
  for GET requests to retrieve data about EC2 services from AWS.
  """

  defmodule RequestTime do
    @moduledoc false

    @doc """
    Returns the current UTC DateTime as NaiveDateTime
    """
    def now() do
      DateTime.utc_now()
      |> DateTime.to_naive()
    end
  end

  @service "ec2"

  @doc """
  Returns a signed URL for accessing EC2 instance data.

  AWS Documentation: http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html
  """
  def build(url) do
    uri = URI.parse(url)
    headers = %{"host" => uri.host}

    request_time = RequestTime.now()
    amz_date = format_time(request_time)
    date = format_date(request_time)

    scope = "#{date}/#{credential_region()}/#{@service}/aws4_request"
    params = build_params(uri.query, scope, amz_date, headers)

    hashed_payload = hash_sha256("")

    string_to_sign =
      uri.path
      |> build_canonical_request(params, headers, hashed_payload)
      |> build_string_to_sign(amz_date, scope)

    signature =
      date
      |> build_signing_key
      |> build_signature(string_to_sign)

    query_string =
      params
      |> Map.put("X-Amz-Signature", signature)
      |> URI.encode_query()
      |> String.replace("+", "%20")

    "#{uri.scheme}://#{uri.authority}#{uri.path || "/"}?#{query_string}"
  end

  defp build_params(query, scope, amz_date, headers) do
    query
    |> decode_query
    |> Map.put("X-Amz-Algorithm", "AWS4-HMAC-SHA256")
    |> Map.put("X-Amz-Credential", "#{access_key_id()}/#{scope}")
    |> Map.put("X-Amz-Date", amz_date)
    |> Map.put("X-Amz-Expires", "86400")
    |> Map.put("X-Amz-SignedHeaders", "#{Map.keys(headers) |> Enum.join(";")}")
  end

  defp decode_query(query)
       when is_nil(query),
       do: Map.new()

  defp decode_query(query), do: URI.decode_query(query)

  defp build_canonical_request(path, params, headers, hashed_payload) do
    query_params =
      params
      |> URI.encode_query()
      |> String.replace("+", "%20")

    header_params =
      headers
      |> Enum.map(fn {key, value} -> "#{String.downcase(key)}:#{String.trim(value)}" end)
      |> Enum.sort(&(&1 < &2))
      |> Enum.join("\n")

    signed_header_params =
      headers
      |> Enum.map(fn {key, _} -> String.downcase(key) end)
      |> Enum.sort(&(&1 < &2))
      |> Enum.join(";")

    encoded_path =
      path
      |> String.split("/")
      |> Enum.map(fn segment -> URI.encode_www_form(segment) end)
      |> Enum.join("/")

    "GET\n#{encoded_path}\n#{query_params}\n#{header_params}\n\n#{signed_header_params}\n#{
      hashed_payload
    }"
  end

  defp build_string_to_sign(canonical_request, timestamp, scope) do
    hashed_canonical_request = hash_sha256(canonical_request)
    "AWS4-HMAC-SHA256\n#{timestamp}\n#{scope}\n#{hashed_canonical_request}"
  end

  defp build_signing_key(date) do
    "AWS4#{secret_access_key()}"
    |> hmac_sha256(date)
    |> hmac_sha256(credential_region())
    |> hmac_sha256(@service)
    |> hmac_sha256("aws4_request")
  end

  defp build_signature(signing_key, string_to_sign) do
    signing_key
    |> hmac_sha256(string_to_sign)
    |> bytes_to_string
  end

  defp hmac_sha256(key, data), do: :crypto.hmac(:sha256, key, data)

  defp hash_sha256(data) do
    :sha256
    |> :crypto.hash(data)
    |> bytes_to_string
  end

  defp bytes_to_string(bytes), do: Base.encode16(bytes, case: :lower)

  defp format_time(time) do
    formatted_time =
      time
      |> NaiveDateTime.to_iso8601()
      |> String.split(".")
      |> List.first()
      |> String.replace("-", "")
      |> String.replace(":", "")

    formatted_time <> "Z"
  end

  defp format_date(date) do
    date
    |> NaiveDateTime.to_date()
    |> Date.to_iso8601()
    |> String.replace("-", "")
  end

  defp access_key_id(), do: Application.fetch_env!(:peerage_ec2, :aws_access_key_id)
  defp secret_access_key(), do: Application.fetch_env!(:peerage_ec2, :aws_secret_access_key)

  defp credential_region() do
    case Application.get_env(:peerage_ec2, :credential_region) do
      nil -> "us-east-1"
      credential_region -> credential_region
    end
  end
end
