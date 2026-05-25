defmodule Midash.Binance do
  @base_url "https://fapi.binance.com"

  def fetch_klines(symbol, interval \\ "1h", limit \\ 48) do
    url = "#{@base_url}/fapi/v1/klines?symbol=#{symbol}&interval=#{interval}&limit=#{limit}"

    case get(url) do
      {:ok, data} ->
        candles =
          Enum.map(data, fn row ->
            %{
              open_time: Enum.at(row, 0),
              open: parse_float(Enum.at(row, 1)),
              high: parse_float(Enum.at(row, 2)),
              low: parse_float(Enum.at(row, 3)),
              close: parse_float(Enum.at(row, 4)),
              volume: parse_float(Enum.at(row, 5)),
              close_time: Enum.at(row, 6)
            }
          end)

        {:ok, candles}

      err ->
        err
    end
  end

  def fetch_premium_index(symbol) do
    url = "#{@base_url}/fapi/v1/premiumIndex?symbol=#{symbol}"

    case get(url) do
      {:ok, data} when is_map(data) ->
        {:ok,
         %{
           symbol: data["symbol"],
           mark_price: parse_float(data["markPrice"]),
           index_price: parse_float(data["indexPrice"]),
           last_funding_rate: parse_float(data["lastFundingRate"]),
           next_funding_time: data["nextFundingTime"],
           interest_rate: parse_float(data["interestRate"])
         }}

      err ->
        err
    end
  end

  def fetch_open_interest(symbol) do
    url = "#{@base_url}/fapi/v1/openInterest?symbol=#{symbol}"

    case get(url) do
      {:ok, data} when is_map(data) ->
        {:ok,
         %{
           symbol: data["symbol"],
           open_interest: parse_float(data["openInterest"]),
           time: data["time"]
         }}

      err ->
        err
    end
  end

  # Fetches 25 hourly OI snapshots and returns current OI plus % change for 1h, 4h, 24h.
  def fetch_open_interest_changes(symbol) do
    url = "#{@base_url}/futures/data/openInterestHist?symbol=#{symbol}&period=1h&limit=25"

    case get(url) do
      {:ok, data} when is_list(data) and length(data) > 0 ->
        points = Enum.map(data, &parse_float(&1["sumOpenInterest"]))
        current = List.last(points)

        change_1h = pct_change(Enum.at(points, -2), current)
        change_4h = pct_change(Enum.at(points, -5), current)
        change_24h = pct_change(List.first(points), current)

        {:ok,
         %{
           open_interest: current,
           change_1h: change_1h,
           change_4h: change_4h,
           change_24h: change_24h
         }}

      {:ok, _} ->
        {:error, "empty response"}

      err ->
        err
    end
  end

  defp pct_change(nil, _), do: nil
  defp pct_change(_, nil), do: nil
  defp pct_change(prev, _curr) when prev == 0.0, do: nil
  defp pct_change(prev, curr), do: (curr - prev) / prev * 100.0

  def fetch_ticker_24h(symbol) do
    url = "#{@base_url}/fapi/v1/ticker/24hr?symbol=#{symbol}"

    case get(url) do
      {:ok, data} when is_map(data) ->
        {:ok,
         %{
           symbol: data["symbol"],
           price_change_percent: parse_float(data["priceChangePercent"]),
           last_price: parse_float(data["lastPrice"]),
           high_price: parse_float(data["highPrice"]),
           low_price: parse_float(data["lowPrice"]),
           volume: parse_float(data["volume"]),
           quote_volume: parse_float(data["quoteVolume"])
         }}

      err ->
        err
    end
  end

  defp get(url) do
    req = Finch.build(:get, url, [{"accept", "application/json"}])

    case Finch.request(req, Midash.Finch) do
      {:ok, %{status: 200, body: body}} -> {:ok, Jason.decode!(body)}
      {:ok, %{status: status, body: body}} -> {:error, "HTTP #{status}: #{body}"}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  defp parse_float(nil), do: nil
  defp parse_float(v) when is_float(v), do: v
  defp parse_float(v) when is_integer(v), do: v / 1.0

  defp parse_float(v) when is_binary(v) do
    case Float.parse(v) do
      {f, _} -> f
      :error -> nil
    end
  end
end
