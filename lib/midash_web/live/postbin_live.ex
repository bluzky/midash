defmodule MidashWeb.PostBinLive do
  use MidashWeb, :live_view
  import MidashWeb.DashboardComponents

  @impl true
  def mount(%{"bin_id" => bin_id}, _session, socket) do
    case Midash.RequestBin.get_requests(bin_id) do
      {:ok, requests} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Midash.PubSub, "bin:#{bin_id}")
        end

        {:ok,
         assign(socket,
           page: :bin,
           bin_id: bin_id,
           requests: requests,
           selected_req: List.first(requests),
           tab: :body,
           page_title: "PostBin · #{bin_id}"
         ), layout: {MidashWeb.Layouts, :dashboard}}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Bin not found")
         |> push_navigate(to: "/toolkit/postbin")}
    end
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page: :list,
       bins: Midash.RequestBin.list_bins(),
       page_title: "PostBin"
     ), layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("new_bin", _params, socket) do
    bin_id = Midash.RequestBin.create_bin()
    {:noreply, push_navigate(socket, to: "/toolkit/postbin/#{bin_id}")}
  end

  def handle_event("delete_bin", %{"id" => bin_id}, socket) do
    Midash.RequestBin.delete_bin(bin_id)
    {:noreply, assign(socket, bins: Midash.RequestBin.list_bins())}
  end

  def handle_event("select_req", %{"id" => id}, socket) do
    req = Enum.find(socket.assigns.requests, &(&1.id == id))
    {:noreply, assign(socket, selected_req: req)}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, tab: String.to_existing_atom(tab))}
  end

  @impl true
  def handle_info({:new_request, req}, socket) do
    requests = [req | socket.assigns.requests]
    selected = socket.assigns.selected_req || req
    {:noreply, assign(socket, requests: requests, selected_req: selected)}
  end

  @impl true
  def render(%{page: :list} = assigns) do
    ~H"""
    <.dashboard_layout current={:toolkit}>
      <.col span={12}>
        <div class="mb-3 flex items-center gap-3">
          <.link
            navigate={~p"/toolkit"}
            class="text-xs text-muted-foreground hover:text-foreground transition-colors font-mono"
          >
            ← toolkit
          </.link>
          <span class="text-xs text-muted-foreground">/</span>
          <span class="text-xs text-foreground font-mono">postbin</span>
        </div>

        <div class="flex flex-col gap-4">
          <div class="flex items-center justify-between">
            <p class="text-xs text-muted-foreground">
              create a bin, send HTTP requests to its URL, inspect them here
            </p>
            <button
              phx-click="new_bin"
              class="flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-xs text-muted-foreground hover:text-foreground hover:bg-secondary transition-colors"
            >
              <Lucideicons.plus class="w-3.5 h-3.5" /> new bin
            </button>
          </div>

          <div :if={@bins == []} class="py-12 text-center text-xs text-muted-foreground">
            no bins yet — create one to start capturing requests
          </div>

          <div :if={@bins != []} class="divide-y divide-border rounded-md border border-border overflow-hidden">
            <div
              :for={bin <- @bins}
              class="group flex items-center gap-4 px-4 py-3 hover:bg-secondary/40 transition-colors"
            >
              <.link navigate={"/toolkit/postbin/#{bin.id}"} class="flex-1 flex items-center gap-4 min-w-0">
                <span class="font-mono text-sm text-foreground">{bin.id}</span>
                <span class="text-xs text-muted-foreground font-mono truncate">
                  {endpoint_url()}/bin/{bin.id}
                </span>
                <span class="ml-auto text-xs text-muted-foreground flex-shrink-0">
                  {bin.count} {if bin.count == 1, do: "request", else: "requests"}
                </span>
                <span class="text-xs text-muted-foreground flex-shrink-0">
                  {format_age(bin.created_at)}
                </span>
              </.link>
              <button
                phx-click="delete_bin"
                phx-value-id={bin.id}
                class="opacity-0 group-hover:opacity-100 p-1 rounded text-muted-foreground hover:text-foreground transition-all"
                title="delete bin"
              >
                <Lucideicons.trash_2 class="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>
      </.col>
    </.dashboard_layout>
    """
  end

  def render(%{page: :bin} = assigns) do
    ~H"""
    <.dashboard_layout current={:toolkit}>
      <.col span={12}>
        <div class="mb-3 flex items-center gap-3">
          <.link
            navigate={~p"/toolkit/postbin"}
            class="text-xs text-muted-foreground hover:text-foreground transition-colors font-mono"
          >
            ← postbin
          </.link>
          <span class="text-xs text-muted-foreground">/</span>
          <span class="text-xs text-foreground font-mono">{@bin_id}</span>
          <div class="ml-auto flex items-center gap-2">
            <span class="text-xs text-muted-foreground font-mono">{endpoint_url()}/bin/{@bin_id}</span>
            <button
              id="copy-bin-url"
              phx-hook="CopyText"
              data-text={endpoint_url() <> "/bin/#{@bin_id}"}
              class="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors"
            >
              <Lucideicons.copy class="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        <div class="grid grid-cols-12 gap-4" style="height: calc(100vh - 10rem);">
          <%!-- Request list --%>
          <div class="col-span-4 flex flex-col rounded-lg border border-border bg-card overflow-hidden">
            <div class="px-4 py-2.5 border-b border-border text-xs uppercase tracking-widest text-muted-foreground flex-shrink-0">
              requests ({length(@requests)})
            </div>

            <div :if={@requests == []} class="flex-1 flex flex-col items-center justify-center text-xs text-muted-foreground gap-2">
              <Lucideicons.radio class="w-6 h-6 opacity-30" />
              waiting for requests…
            </div>

            <div :if={@requests != []} class="flex-1 overflow-y-auto divide-y divide-border">
              <div
                :for={req <- @requests}
                phx-click="select_req"
                phx-value-id={req.id}
                class={[
                  "flex items-center gap-3 px-4 py-3 cursor-pointer hover:bg-secondary/50 transition-colors",
                  if(@selected_req && @selected_req.id == req.id, do: "bg-secondary", else: "")
                ]}
              >
                <span class={["text-[10px] font-bold px-1.5 py-0.5 rounded flex-shrink-0", method_color(req.method)]}>
                  {req.method}
                </span>
                <span class="text-xs font-mono text-foreground truncate flex-1">{req.path}</span>
                <span class="text-[10px] text-muted-foreground flex-shrink-0">{format_time(req.inserted_at)}</span>
              </div>
            </div>
          </div>

          <%!-- Detail panel --%>
          <div class="col-span-8 flex flex-col rounded-lg border border-border bg-card overflow-hidden">
            <div class="px-4 py-2.5 border-b border-border text-xs uppercase tracking-widest text-muted-foreground flex-shrink-0">
              detail
            </div>

            <div :if={is_nil(@selected_req)} class="flex-1 flex items-center justify-center text-xs text-muted-foreground">
              select a request to inspect
            </div>

            <div :if={@selected_req} class="flex-1 flex flex-col overflow-hidden">
              <div class="flex items-center gap-3 px-4 py-3 border-b border-border flex-shrink-0">
                <span class={["text-xs font-bold px-2 py-1 rounded", method_color(@selected_req.method)]}>
                  {@selected_req.method}
                </span>
                <span class="text-sm font-mono text-foreground">{@selected_req.path}</span>
                <span class="ml-auto text-[10px] text-muted-foreground">{format_time(@selected_req.inserted_at)}</span>
              </div>

              <div class="flex gap-1 border-b border-border px-4 flex-shrink-0">
                <button
                  :for={tab <- [:body, :headers, :query]}
                  phx-click="switch_tab"
                  phx-value-tab={tab}
                  class={[
                    "px-3 py-2 text-xs border-b-2 -mb-px transition-colors",
                    if(@tab == tab,
                      do: "border-foreground text-foreground",
                      else: "border-transparent text-muted-foreground hover:text-foreground"
                    )
                  ]}
                >
                  {tab}
                  <span :if={tab == :headers} class="ml-1 text-[10px] opacity-60">({map_size(@selected_req.headers)})</span>
                  <span :if={tab == :query} class="ml-1 text-[10px] opacity-60">({map_size(@selected_req.query)})</span>
                </button>
              </div>

              <div class="flex-1 overflow-y-auto p-4">
                <div :if={@tab == :body}>
                  <div :if={empty_body?(@selected_req.body)} class="text-xs text-muted-foreground">empty body</div>
                  <div :if={not empty_body?(@selected_req.body)}>
                    <div class="mb-2 text-[10px] text-muted-foreground font-mono">content-type: {@selected_req.content_type}</div>
                    <pre class="rounded border border-border bg-background p-4 text-xs font-mono text-foreground overflow-x-auto whitespace-pre-wrap break-all">{format_body(@selected_req.body)}</pre>
                  </div>
                </div>

                <div :if={@tab == :headers}>
                  <div :if={@selected_req.headers == %{}} class="text-xs text-muted-foreground">no headers</div>
                  <div :if={@selected_req.headers != %{}} class="divide-y divide-border rounded border border-border overflow-hidden">
                    <div :for={{k, v} <- Enum.sort(@selected_req.headers)} class="flex px-3 py-2 text-xs font-mono gap-4">
                      <span class="text-muted-foreground w-56 flex-shrink-0 truncate">{k}</span>
                      <span class="text-foreground break-all">{v}</span>
                    </div>
                  </div>
                </div>

                <div :if={@tab == :query}>
                  <div :if={@selected_req.query == %{}} class="text-xs text-muted-foreground">no query params</div>
                  <div :if={@selected_req.query != %{}} class="divide-y divide-border rounded border border-border overflow-hidden">
                    <div :for={{k, v} <- Enum.sort(@selected_req.query)} class="flex px-3 py-2 text-xs font-mono gap-4">
                      <span class="text-muted-foreground w-56 flex-shrink-0 truncate">{k}</span>
                      <span class="text-foreground break-all">{v}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </.col>
    </.dashboard_layout>
    """
  end

  defp endpoint_url, do: MidashWeb.Endpoint.url()

  defp method_color("GET"), do: "bg-blue-500/20 text-blue-400"
  defp method_color("POST"), do: "bg-green-500/20 text-green-400"
  defp method_color("PUT"), do: "bg-yellow-500/20 text-yellow-400"
  defp method_color("PATCH"), do: "bg-orange-500/20 text-orange-400"
  defp method_color("DELETE"), do: "bg-red-500/20 text-red-400"
  defp method_color(_), do: "bg-muted text-muted-foreground"

  defp format_time(dt), do: Calendar.strftime(dt, "%H:%M:%S")

  defp format_age(dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)
    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      true -> "#{div(diff, 3600)}h ago"
    end
  end

  defp empty_body?(body) when body == "" or body == %{} or is_nil(body), do: true
  defp empty_body?(_), do: false

  defp format_body(body) when is_map(body), do: Jason.encode!(body, pretty: true)
  defp format_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> Jason.encode!(decoded, pretty: true)
      _ -> body
    end
  end
  defp format_body(body), do: Kernel.inspect(body)
end
