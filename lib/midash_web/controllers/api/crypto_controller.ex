defmodule MidashWeb.API.CryptoController do
  use MidashWeb, :controller

  alias Midash.Binance

  def funding(conn, params) do
    symbols = Map.get(params, "symbols", ["ETHUSDT", "BTCUSDT"])

    results =
      Enum.map(symbols, fn symbol ->
        with {:ok, premium} <- Binance.fetch_premium_index(symbol),
             {:ok, oi} <- Binance.fetch_open_interest_changes(symbol) do
          Map.merge(premium, %{
            open_interest: oi.open_interest,
            oi_change_1h: oi.change_1h,
            oi_change_4h: oi.change_4h,
            oi_change_24h: oi.change_24h
          })
        else
          {:error, reason} -> %{symbol: symbol, error: reason}
        end
      end)

    json(conn, %{data: results})
  end

  def klines(conn, params) do
    symbol = Map.get(params, "symbol", "ETHUSDT")
    interval = Map.get(params, "interval", "1h")
    limit = params |> Map.get("limit", "91") |> parse_int(91)

    case Binance.fetch_klines(symbol, interval, limit) do
      {:ok, candles} -> json(conn, %{data: candles})
      {:error, reason} -> conn |> put_status(502) |> json(%{error: reason})
    end
  end

  defp parse_int(s, default) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> default
    end
  end
end
