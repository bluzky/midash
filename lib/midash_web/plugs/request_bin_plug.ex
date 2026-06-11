defmodule MidashWeb.RequestBinPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    bin_id = conn.path_params["bin_id"]

    content_type = get_req_header(conn, "content-type") |> List.first() || ""

    attrs = %{
      method: conn.method,
      path: "/" <> Enum.join(conn.path_info, "/"),
      headers: Map.new(conn.req_headers),
      query: conn.query_params,
      body: conn.body_params,
      content_type: content_type
    }

    case Midash.RequestBin.record_request(bin_id, attrs) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{ok: true, bin_id: bin_id}))
        |> halt()

      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{error: "bin not found"}))
        |> halt()
    end
  end
end
