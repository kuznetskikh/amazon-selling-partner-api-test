defmodule AmazonSellingPartnerApi do
  @moduledoc """
  Service for interaction with Amazon Selling Partner API.
  """
  alias AmazonSellingPartnerApi.Client

  @max_page_number 10
  @pagination_timeout 500

  @spec list_purchase_orders(created_after :: DateTime.t(), vnedor_code :: binary()) ::
          {:ok, list(map())} | {:error, any()}
  def list_purchase_orders(created_after, vendor_code) do
    list_purchase_orders_result =
      Enum.reduce_while(
        1..@max_page_number,
        %{
          pagination_token: nil,
          purchase_orders: [],
          error: nil
        },
        fn _, acc ->
          list_purchase_orders_accumulate(created_after, vendor_code, acc)
        end
      )

    case list_purchase_orders_result do
      %{purchase_orders: purchase_orders} ->
        {:ok, purchase_orders}

      %{error: error} ->
        {:error, error}
    end
  end

  defp list_purchase_orders_accumulate(created_after, vendor_code, acc) do
    case list_purchase_orders_paginate(created_after, vendor_code, acc) do
      {
        :ok,
        %{pagination_token: nil} = last_acc
      } ->
        {:halt, last_acc}

      {
        :ok,
        %{pagination_token: _} = next_acc
      } ->
        Process.sleep(@pagination_timeout)

        {:cont, next_acc}

      {:error, error} ->
        {:halt, %{error: error}}
    end
  end

  defp list_purchase_orders_paginate(
         created_after,
         vendor_code,
         %{
           pagination_token: pagination_token,
           purchase_orders: purchase_orders
         }
       ) do
    params = [
      created_after: DateTime.to_iso8601(created_after),
      ordering_vendor_code: vendor_code,
      # Use ascentive sorting order for purchase order creation date, because we
      # set a limit on the count of pages retrieved per one call, not to miss
      # older purchase orders on the next call.
      sort_order: "ASC",
      next_token: pagination_token
    ]

    case Client.purchase_orders(params) do
      {
        :ok,
        %{
          status_code: 200,
          body: body
        }
      } ->
        response_payload = Jason.decode!(body)["payload"]

        {
          :ok,
          %{
            pagination_token: response_payload["pagination"]["nextToken"],
            purchase_orders: purchase_orders ++ response_payload["orders"]
          }
        }

      {:ok, error_response} ->
        {:error, error_response}

      {:error, _} = error_result ->
        error_result
    end
  end
end
