defmodule MidashWeb.PostBinChannel do
  use Phoenix.Channel

  @impl true
  def join("bin:" <> bin_id, _params, socket) do
    case Midash.RequestBin.get_requests(bin_id) do
      {:ok, requests} ->
        Phoenix.PubSub.subscribe(Midash.PubSub, "bin:#{bin_id}")
        {:ok, %{requests: serialize_requests(requests)}, assign(socket, bin_id: bin_id)}

      {:error, :not_found} ->
        {:error, %{reason: "bin not found"}}
    end
  end

  @impl true
  def handle_info({:new_request, req}, socket) do
    push(socket, "new_request", serialize_request(req))
    {:noreply, socket}
  end

  defp serialize_requests(reqs), do: Enum.map(reqs, &serialize_request/1)

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
