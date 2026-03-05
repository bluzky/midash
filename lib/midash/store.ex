defmodule Midash.Store do
  @moduledoc """
  Lightweight key-value store for widgets, backed by CubDB.

  Keys are namespaced by widget id to prevent collisions:

      Midash.Store.put(:weather, :last_data, %{temp: 22})
      Midash.Store.get(:weather, :last_data)
      Midash.Store.delete(:weather, :last_data)
      Midash.Store.get_all(:weather)

  Compound keys are stored as `{widget_id, key}` tuples.
  """

  @db Midash.Store.DB

  @doc "Get a value for a widget key. Returns `default` if not found (default: nil)."
  def get(widget_id, key, default \\ nil) do
    CubDB.get(@db, {widget_id, key}, default)
  end

  @doc "Store a value under a widget key."
  def put(widget_id, key, value) do
    CubDB.put(@db, {widget_id, key}, value)
  end

  @doc "Delete a widget key."
  def delete(widget_id, key) do
    CubDB.delete(@db, {widget_id, key})
  end

  @doc "Return all key-value pairs for a widget as a map."
  def get_all(widget_id) do
    # Select all keys that start with {widget_id, _} by using min/max_key_inclusive bounds.
    # Erlang term order: tuples of same arity compare element by element.
    # {widget_id, nil} is the lowest possible value for this widget's namespace.
    # {widget_id, {}} is higher than any atom or binary, covering all practical keys.
    CubDB.select(@db,
      min_key: {widget_id, nil},
      max_key: {widget_id, {}},
      max_key_inclusive: true
    )
    |> Enum.reduce(%{}, fn {{_id, k}, v}, acc -> Map.put(acc, k, v) end)
  end
end
