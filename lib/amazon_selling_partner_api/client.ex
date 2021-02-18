defmodule AmazonSellingPartnerApi.Client do
  @moduledoc """
  HTTP client for interaction with Amazon Selling Partner API.
  """

  alias OAuth2.Client, as: AuthClient
  alias OAuth2.Strategy.Refresh, as: AuthStrategy

  @aws_service "execute-api"

  @access_token_expiration_threshold_seconds 60

  @spec purchase_orders(opts :: Keyword.t()) :: {:ok, binary(), list(map())} | {:error, any()}
  def purchase_orders(opts \\ []) do
    api_site = fetch_config_value!(:api_site)

    query_params =
      opts
      |> camelize_keys()
      |> URI.encode_query()

    url =
      "#{api_site}/vendor/orders/v1/purchaseOrders"
      |> URI.parse()
      |> Map.put(:query, query_params)
      |> URI.to_string()

    case get_headers(url, "GET") do
      {:ok, headers} ->
        url
        |> HTTPoison.get(headers)
        |> handle_response(["orders"], [])

      {:error, _any_reason} = error_result ->
        error_result
    end
  end

  defp camelize_keys([]), do: []
  defp camelize_keys([{k, v} | rest]), do: [{camelize(k), v} | camelize_keys(rest)]

  defp camelize(atom) do
    [h | rest] =
      atom
      |> to_string()
      |> String.split("_")

    [h | Enum.map(rest, &String.capitalize/1)]
    |> Enum.join()
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
            region(),
            @aws_service,
            %{"x-amz-access-token" => access_token.access_token}
          )

        {:ok, headers}

      {:error, _any_reason} = error_result ->
        error_result
    end
  end

  defp obtain_access_token do
    case Application.get_env(:amazon_selling_partner_api, :access_token) do
      nil ->
        update_access_token()

      access_token ->
        # Verify access token expiration time using a little threshold and request new one if
        # required.
        access_token_clarified_expires_at =
          DateTime.add(
            DateTime.utc_now(),
            @access_token_expiration_threshold_seconds
          )

        access_token_expires_at = DateTime.from_unix!(access_token.expires_at)

        if DateTime.compare(
             access_token_clarified_expires_at,
             access_token_expires_at
           ) == :gt do
          update_access_token()
        else
          {:ok, access_token}
        end
    end
  end

  defp update_access_token do
    case get_access_token() do
      {:ok, access_token} ->
        Application.put_env(:amazon_selling_partner_api, :access_token, access_token)

        {:ok, access_token}

      {:error, _any_reason} = error_result ->
        error_result
    end
  end

  defp get_access_token do
    access_token_site = fetch_config_value!(:access_token_site)
    client_id = fetch_config_value!(:client_id)
    client_secret = fetch_config_value!(:client_secret)
    refresh_token = fetch_config_value!(:refresh_token)

    client =
      AuthClient.new(
        strategy: AuthStrategy,
        site: access_token_site,
        token_url: "/auth/o2/token",
        serializers: %{"application/json" => Jason},
        client_id: client_id,
        client_secret: client_secret,
        params: %{"refresh_token" => refresh_token}
      )

    case AuthClient.get_token(client) do
      {:ok, %AuthClient{token: access_token}} ->
        {:ok, access_token}

      {:error, _any_reason} = error_result ->
        error_result
    end
  end

  defp region do
    Application.get_env(:ex_aws, :region)
  end

  defp fetch_config_value!(key) do
    Application.fetch_env!(:amazon_selling_partner_api, key)
  end

  defp handle_response(
         {
           :ok,
           %{
             status_code: 200,
             body: body
           }
         },
         keys,
         default_value
       ) do
    case Jason.decode(body) do
      {:ok, %{"payload" => payload}} ->
        {
          :ok,
          get_in(payload, ["pagination", "nextToken"]),
          get_in(payload, keys) || default_value
        }

      {:ok, error_response_body} ->
        {:error, error_response_body}

      {:error, _any_reason} = error_result ->
        error_result
    end
  end

  defp handle_response(
         {:ok, error_response},
         _any_keys,
         _any_default_value
       ),
       do: {:error, error_response}

  defp handle_response(
         error_result = {:error, _any_reason},
         _any_keys,
         _any_default_value
       ),
       do: error_result
end
