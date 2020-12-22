defmodule AmazonSellingPartnerApi do
  @moduledoc false

  @host "sellingpartnerapi-na.amazon.com"
  @region "us-east-1"
  @service :"execute-api"

  def list_purchase_orders(next_token \\ nil) do
    token_param = next_token_param(next_token)
    url = "https://#{@host}/vendor/orders/v1/purchaseOrders?limit=10#{token_param}"

    headers = get_headers(url)

    case HTTPoison.get!(url, headers) do
      %{status_code: 200, body: body} -> Jason.decode!(body)["payload"]
      error -> error
    end
  end

  defp next_token_param(nil), do: nil
  defp next_token_param(token), do: "&nextToken=#{token}"

  def get_headers(url, action \\ "GET") do
    access_key_id = Application.get_env(:amazon_selling_partner_api, :access_key_id)
    secret_access_key = Application.get_env(:amazon_selling_partner_api, :secret_access_key)

    access_token = get_access_token()
    access_key_id = Application.get_env(:amazon_selling_partner_api, :access_key_id)
    secret_access_key = Application.get_env(:amazon_selling_partner_api, :secret_access_key)

    AWSAuth.sign_authorization_header(
      access_key_id,
      secret_access_key,
      action,
      url,
      @region,
      to_string(@service),
      %{"x-amz-access-token" => access_token}
    )
  end

  def get_access_token do
    client_id = Application.get_env(:amazon_selling_partner_api, :client_id)
    client_secret = Application.get_env(:amazon_selling_partner_api, :client_secret)
    refresh_token = Application.get_env(:amazon_selling_partner_api, :refresh_token)

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
end
