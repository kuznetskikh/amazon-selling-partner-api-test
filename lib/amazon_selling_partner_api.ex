defmodule AmazonSellingPartnerApi do
  @moduledoc false

  def list_purchase_orders(
        client_id,
        client_secret,
        refresh_token,
        access_key_id,
        secret_access_key
      ) do
    access_token = get_access_token(client_id, client_secret, refresh_token)
    headers = get_headers(access_key_id, secret_access_key, access_token)

    presigned_url =
      get_presigned_url(
        access_key_id,
        secret_access_key,
        access_token
      )

    IO.puts(presigned_url)

    HTTPoison.get!(
      "https://sellingpartnerapi-na.amazon.com/vendor/orders/v1/purchaseOrders?limit=10",
      headers
    )
  end

  defp get_headers(access_key_id, secret_access_key, access_token) do
    {:ok, headers} =
      ExAws.Auth.headers(
        :get,
        "https://sellingpartnerapi-na.amazon.com/vendor/orders/v1/purchaseOrders?limit=10",
        String.to_atom("execute-api"),
        ExAws.Config.new(
          :iot,
          region: "us-east-1",
          access_key_id: access_key_id,
          secret_access_key: secret_access_key
        ),
        [
          {"x-amz-access-token", access_token},
          {"user-agent", "hackney/1.17.0"}
        ],
        nil
      )

    headers
  end

  defp get_access_token(client_id, client_secret, refresh_token) do
    refresh_client =
      OAuth2.Client.new(
        strategy: OAuth2.Strategy.Refresh,
        site: "https://api.amazon.com",
        token_url: "/auth/o2/token",
        serializers: %{
          "application/json" => Jason
        },
        client_id: client_id,
        client_secret: client_secret,
        params: %{
          "refresh_token" => refresh_token
        }
      )

    %OAuth2.Client{
      token: %OAuth2.AccessToken{
        access_token: access_token
      }
    } = OAuth2.Client.get_token!(refresh_client)

    access_token
  end

  defp get_presigned_url(access_key_id, secret_access_key, access_token) do
    date_time = :calendar.universal_time()
    {{year, month, day}, {hour, minute, second}} = date_time

    {:ok, presigned_url} =
      ExAws.Auth.presigned_url(
        :get,
        "https://sellingpartnerapi-na.amazon.com/vendor/orders/v1/purchaseOrders",
        String.to_atom("execute-api"),
        date_time,
        ExAws.Config.new(
          :iot,
          region: "us-east-1",
          access_key_id: access_key_id,
          secret_access_key: secret_access_key
        ),
        30,
        [],
        nil,
        [
          {"x-amz-access-token", access_token},
          {"x-amz-date", "#{year}#{month}#{day}T#{hour}#{minute}#{second}Z"},
          {"user-agent", "hackney/1.17.0"}
        ]
      )

    presigned_url
  end
end
