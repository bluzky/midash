defmodule MidashWeb.BarcodeLive do
  use MidashWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, input: "", barcodes: [], error: nil),
     layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("generate", %{"input" => input}, socket) do
    lines =
      input
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    barcodes =
      Enum.map(lines, fn value ->
        case Barlix.Code128.encode(value) do
          {:ok, code} ->
            {:ok, svg} = Barlix.SVG.print(code, xdim: 2, height: 80)
            %{value: value, svg: svg, error: nil}

          {:error, reason} ->
            %{value: value, svg: nil, error: Kernel.inspect(reason)}
        end
      end)

    {:noreply, assign(socket, input: input, barcodes: barcodes, error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout current={MidashWeb.Nav.current_from_module(MidashWeb.ToolkitLive)}>
      <.col span={12}>
        <div class="mb-3 flex items-center gap-3">
          <.link
            navigate={~p"/toolkit"}
            class="text-xs text-muted-foreground hover:text-foreground transition-colors font-mono"
          >
            ← toolkit
          </.link>
          <span class="text-xs text-muted-foreground">/</span>
          <span class="text-xs text-foreground font-mono">barcode generator</span>
        </div>

        <div class="flex flex-col gap-4">
          <form phx-submit="generate" class="flex flex-col gap-2">
            <label class="text-xs text-muted-foreground uppercase tracking-widest">
              Barcodes (one per line)
            </label>
            <textarea
              name="input"
              rows="6"
              placeholder={"ABC-001\nABC-002\nABC-003"}
              class="w-full rounded border border-border bg-background p-3 font-mono text-sm text-foreground resize-y focus:outline-none focus:ring-1 focus:ring-ring"
            >{@input}</textarea>
            <div class="flex items-center gap-3">
              <button
                type="submit"
                class="px-4 py-2 rounded border border-border bg-secondary text-foreground text-xs font-mono hover:bg-secondary/80 transition-colors"
              >
                generate
              </button>
              <button
                :if={@barcodes != []}
                type="button"
                onclick="window.print()"
                class="px-4 py-2 rounded border border-border bg-secondary text-foreground text-xs font-mono hover:bg-secondary/80 transition-colors"
              >
                print
              </button>
            </div>
          </form>

          <div :if={@barcodes != []} id="barcode-grid" class="grid grid-cols-2 gap-4 print:gap-2">
            <div
              :for={barcode <- @barcodes}
              class="flex flex-col items-center justify-center gap-1 rounded border border-border bg-card p-4 print:border print:border-gray-300 print:rounded print:p-2"
            >
              <div :if={barcode.error} class="text-xs text-destructive font-mono">
                {barcode.value}: {barcode.error}
              </div>
              <div
                :if={barcode.svg}
                class="[&_svg]:max-w-full [&_svg]:h-auto"
              >
                {Phoenix.HTML.raw(barcode.svg)}
              </div>
              <span class="text-xs font-mono text-foreground print:text-black">
                {barcode.value}
              </span>
            </div>
          </div>
        </div>
      </.col>
    </.dashboard_layout>
    """
  end
end
