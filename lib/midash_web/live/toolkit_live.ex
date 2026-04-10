defmodule MidashWeb.ToolkitLive do
  use MidashWeb, :live_view

  @tools [
    %{id: :elixir_execute, label: "Elixir Execute", description: "Run Elixir code with an input string", path: "/toolkit/elixir-execute"},
    %{id: :barcode, label: "Barcode Generator", description: "Generate Code128 barcodes, one per line, printable 2-column grid", path: "/toolkit/barcode"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, search: "", filtered_tools: @tools),
     layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    filtered =
      if q == "" do
        @tools
      else
        q_lower = String.downcase(q)
        Enum.filter(@tools, fn tool ->
          String.contains?(String.downcase(tool.label), q_lower) or
            String.contains?(String.downcase(tool.description), q_lower)
        end)
      end

    {:noreply, assign(socket, search: q, filtered_tools: filtered)}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, search: "", filtered_tools: @tools)}
  end

  def handle_event("keydown", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("open_first", _params, socket) do
    case socket.assigns.filtered_tools do
      [first | _] -> {:noreply, push_navigate(socket, to: first.path)}
      [] -> {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout current={MidashWeb.Nav.current_from_module(__MODULE__)}>
      <.col span={12}>
        <.widget id="w-toolkit-search" title="toolkit">
          <div class="flex flex-col gap-4">
            <form phx-submit="open_first" phx-change="search">
              <input
                type="text"
                name="q"
                value={@search}
                placeholder="search tools..."
                autofocus
                autocomplete="off"
                phx-keydown="keydown"
                class="w-full rounded border border-border bg-background px-4 py-3 font-mono text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring"
              />
            </form>

            <div class="grid grid-cols-3 gap-3">
              <.link
                :for={tool <- @filtered_tools}
                navigate={tool.path}
                class="flex flex-col gap-1 rounded border border-border bg-card p-4 hover:bg-secondary/50 transition-colors"
              >
                <span class="text-sm font-mono text-foreground">{tool.label}</span>
                <span class="text-xs text-muted-foreground">{tool.description}</span>
              </.link>

              <div
                :if={@filtered_tools == []}
                class="col-span-3 text-center text-sm text-muted-foreground py-8"
              >
                no tools match "{@search}"
              </div>
            </div>
          </div>
        </.widget>
      </.col>
    </.dashboard_layout>
    """
  end
end
