defmodule AmazonSellingPartnerApi.Client do
  @moduledoc """
  HTTP client for interaction with Amazon Selling Partner API.
  """

  @api_site "https://sellingpartnerapi-na.amazon.com"
  @aws_region "us-east-1"
  @aws_service "execute-api"

  @access_token_site "https://api.amazon.com"
  @access_token_path "/auth/o2/token"
  @access_token_expiration_threshold_seconds 60

  def purchase_orders(opts \\ []) do
    query_params = URI.encode_query(opts)

    url =
      "#{@api_site}/vendor/orders/v1/purchaseOrders"
      |> URI.parse()
      |> Map.put(:query, query_params)
      |> URI.to_string()

    case get_headers(url, "GET") do
      {:ok, headers} ->
        HTTPoison.get(url, headers)

      {:error, _} = error_result ->
        error_result
    end
  end

  defp get_headers(url, http_method) do
    case obtain_access_token() do
      {:ok, access_token} ->
        access_key_id = fetch_config_value!(:access_key_id)
        secret_access_key = fetch_config_value!(:secret_access_key)

        headers =
          AWSAuth.sign_authorization_header(
            access_key_id,
            secret_access_key,
            http_method,
            url,
            @aws_region,
            @aws_service,
            %{"x-amz-access-token" => access_token.access_token}
          )

        {:ok, headers}

      {:error, _} = error_result ->
        error_result
    end
  end

  defp obtain_access_token do
    case Application.get_env(:amazon_selling_partner_api, :access_token) do
      nil ->
        update_access_token()

      access_token ->
        # Verify access token expiration time using a little threshold and
        # request new one if required.
        access_token_clarified_expires_at =
          DateTime.add(
            DateTime.utc_now(),
            @access_token_expiration_threshold_seconds
          )

        access_token_expires_at = DateTime.from_unix!(access_token.expires_at)

        if DateTime.compare(
             access_token_clarified_expires_at,
             access_token_expires_at
           ) ===
             :gt do
          update_access_token()
        else
          {:ok, access_token}
        end
    end
  end

  defp update_access_token do
    case get_access_token() do
      {:ok, access_token} ->
        Application.put_env(
          :amazon_selling_partner_api,
          :access_token,
          access_token
        )

        {:ok, access_token}

      {:error, _} = error_result ->
        error_result
    end
  end

  def get_access_token do
    client_id = fetch_config_value!(:client_id)
    client_secret = fetch_config_value!(:client_secret)
    refresh_token = fetch_config_value!(:refresh_token)

    client =
      OAuth2.Client.new(
        strategy: OAuth2.Strategy.Refresh,
        site: @access_token_site,
        token_url: @access_token_path,
        serializers: %{"application/json" => Jason},
        client_id: client_id,
        client_secret: client_secret,
        params: %{"refresh_token" => refresh_token}
      )

    case OAuth2.Client.get_token(client) do
      {:ok, %OAuth2.Client{token: access_token}} ->
        {:ok, access_token}

      {:error, _} = error_result ->
        error_result
    end
  end

  defp fetch_config_value!(key) do
    Application.fetch_env!(:amazon_selling_partner_api, key)
  end
end
