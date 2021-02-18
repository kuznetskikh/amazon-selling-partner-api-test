defmodule AmazonSellingPartnerApi do
  @moduledoc """
  Service for interaction with Amazon Selling Partner API.
  """

  alias AmazonSellingPartnerApi.Client

  @pagination_timeout 500

  @spec list_purchase_orders(created_after :: DateTime.t(), vendor_code :: binary()) ::
          {:ok, list(map())} | {:error, any()}
  def list_purchase_orders(created_after, vendor_code) do
    list_purchase_orders_result =
      fn -> :unused end
      |> Stream.repeatedly()
      |> Enum.reduce_while(
        {:ok, nil, []},
        fn _any, acc ->
          list_purchase_orders_accumulate(created_after, vendor_code, acc)
        end
      )

    case list_purchase_orders_result do
      {:ok, _any_pagination_token, purchase_orders} ->
        {:ok, purchase_orders}

      {:error, _any_reason} = error_result ->
        error_result
    end
  end

  defp list_purchase_orders_accumulate(created_after, vendor_code, acc) do
    case list_purchase_orders_paginate(created_after, vendor_code, acc) do
      {:ok, nil, _any_purchase_orders} = last_acc ->
        {:halt, last_acc}

      {:ok, _any_pagination_token, _any_purchase_orders} = next_acc ->
        Process.sleep(@pagination_timeout)

        {:cont, next_acc}

      {:error, _any_reason} = error_result ->
        {:halt, error_result}
    end
  end

  defp list_purchase_orders_paginate(
         created_after,
         vendor_code,
         {:ok, pagination_token, purchase_orders}
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
      {:ok, pagination_token, next_purchase_orders} ->
        {:ok, pagination_token, purchase_orders ++ next_purchase_orders}

      {:error, _any_reason} = error_result ->
        error_result
    end
  end
end
