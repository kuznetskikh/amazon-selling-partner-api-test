defmodule AmazonSellingPartnerApi do
  @moduledoc false

  @host "sellingpartnerapi-na.amazon.com"
  @region "us-east-1"
  @service :"execute-api"
  @default_per_page 10

  def list_purchase_orders(opts \\ []) do
    opts = Keyword.put_new(opts, :limit, @default_per_page)

    url = "https://#{@host}/vendor/orders/v1/purchaseOrders#{query_from(opts)}"

    headers = get_headers(url)

    case HTTPoison.get!(url, headers) do
      %{status_code: 200, body: body} -> {:ok, Jason.decode!(body)["payload"]}
      error -> {:error, error}
    end
  end

  defp query_from([]), do: nil

  defp query_from([{key, value} | opts]) do
    "?#{camelize(key)}=#{value}#{do_query_from(opts)}"
  end

  defp do_query_from([]), do: nil

  defp do_query_from([{key, value} | opts]) do
    "&#{camelize(key)}=#{value}#{do_query_from(opts)}"
  end

  defp next_token_param(nil), do: nil
  defp next_token_param(token), do: "&nextToken=#{token}"

  defp camelize(atom) do
    [h | rest] =
      atom
      |> to_string()
      |> String.split("_")

    [h | Enum.map(rest, &String.capitalize/1)]
    |> Enum.join()
  end

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
