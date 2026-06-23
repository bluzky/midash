defmodule Midash.ConfigStore do
  @moduledoc """
  Local JSON-backed runtime config for Midash.

  Values in `.midash_config.json` override environment variables. This is intended
  for local-only secrets/configuration.
  """

  require Logger

  def path, do: Path.expand(".midash_config.json", File.cwd!())

  def get(key, default \\ "") when is_binary(key) do
    case Map.get(all(), key) do
      value when is_binary(value) and value != "" -> value
      _ -> System.get_env(key, default)
    end
  end

  def all do
    case File.read(path()) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, data} when is_map(data) ->
            data

          _ ->
            Logger.error("[ConfigStore] Config file contains invalid JSON, ignoring")
            %{}
        end

      {:error, :enoent} ->
        %{}

      {:error, reason} ->
        Logger.error("[ConfigStore] Failed to read config file: #{inspect(reason)}")
        %{}
    end
  end

  def put_many(values) when is_map(values) do
    existing = all()

    cleaned =
      values
      |> Enum.map(fn {k, v} -> {to_string(k), normalize_value(v)} end)
      |> Enum.reject(fn {_k, v} -> v == nil or v == "" end)
      |> Map.new()

    data = Map.merge(existing, cleaned)

    with {:ok, json} <- Jason.encode(data, pretty: true),
         :ok <- File.write(path(), json <> "\n") do
      {:ok, data}
    end
  end

  def configured?(key), do: get(key, "") != ""

  defp normalize_value(nil), do: nil
  defp normalize_value(v) when is_binary(v), do: String.trim(v)
  defp normalize_value(v) when is_list(v) or is_map(v), do: nil
  defp normalize_value(v), do: v |> to_string() |> String.trim()
end
