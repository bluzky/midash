defmodule MidashWeb.API.PostbinController do
  use MidashWeb, :controller

  def index(conn, _params) do
    bins = Midash.RequestBin.list_bins()
    json(conn, %{data: Enum.map(bins, &serialize_bin/1)})
  end

  def create(conn, _params) do
    bin_id = Midash.RequestBin.create_bin()
    json(conn, %{id: bin_id})
  end

  def requests(conn, %{"id" => bin_id}) do
    case Midash.RequestBin.get_requests(bin_id) do
      {:ok, requests} ->
        json(conn, %{data: Enum.map(requests, &serialize_request/1)})

      {:error, :not_found} ->
        conn |> put_status(404) |> json(%{error: "bin not found"})
    end
  end

  def delete(conn, %{"id" => bin_id}) do
    Midash.RequestBin.delete_bin(bin_id)
    json(conn, %{ok: true})
  end

  defp serialize_bin(bin) do
    %{
      id: bin.id,
      count: bin.count,
      created_at: DateTime.to_iso8601(bin.created_at)
    }
  end

  defp serialize_request(req) do
    %{
      id: req.id,
      method: req.method,
      path: req.path,
      query: req.query,
      headers: req.headers,
      body: req.body,
      content_type: req.content_type,
      inserted_at: DateTime.to_iso8601(req.inserted_at)
    }
  end
end
