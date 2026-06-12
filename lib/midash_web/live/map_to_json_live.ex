defmodule MidashWeb.MapToJsonLive do
  use MidashWeb, :live_view

  @default_input ~s(%{\n  name: "Alice",\n  age: 30,\n  tags: ["elixir", "phoenix"],\n  meta: %{active: true}\n})

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, input: @default_input, output: nil, error: nil),
     layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("convert", %{"input" => input}, socket) do
    case eval_map(input) do
      {:ok, value} ->
        case Jason.encode(value, pretty: true) do
          {:ok, json} -> {:noreply, assign(socket, output: json, error: nil)}
          {:error, err} -> {:noreply, assign(socket, error: "JSON encode error: #{Kernel.inspect(err)}", output: nil)}
        end

      {:error, msg} ->
        {:noreply, assign(socket, error: msg, output: nil)}
    end
  end

  defp eval_map(input) do
    {value, _binding} = Code.eval_string(input, [])
    {:ok, value}
  rescue
    e -> {:error, Exception.message(e)}
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
          <span class="text-xs text-foreground font-mono">map → json</span>
        </div>

        <form phx-submit="convert" class="flex flex-col gap-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col gap-1">
              <label class="text-xs text-muted-foreground uppercase tracking-widest">Elixir Map</label>
              <textarea
                name="input"
                class="h-96 w-full rounded border border-border bg-background p-3 font-mono text-sm text-foreground resize-none focus:outline-none focus:ring-1 focus:ring-ring"
                placeholder="%{key: &quot;value&quot;}"
                spellcheck="false"
              ><%= @input %></textarea>
            </div>

            <div class="flex flex-col gap-1">
              <label class="text-xs text-muted-foreground uppercase tracking-widest">JSON</label>
              <pre
                id="json-output"
                class={[
                  "h-96 rounded border border-border p-3 text-sm font-mono overflow-auto whitespace-pre-wrap",
                  if(@error, do: "bg-destructive/10 text-destructive", else: "bg-secondary text-foreground")
                ]}
              >{cond do
                @error -> @error
                @output -> @output
                true -> "// output appears here"
              end}</pre>
            </div>
          </div>

          <div class="flex justify-between">
            <button
              type="submit"
              class="px-4 py-2 rounded border border-border bg-secondary text-foreground text-xs font-mono hover:bg-secondary/80 transition-colors"
            >
              convert
            </button>
            <button
              :if={@output}
              type="button"
              id="copy-btn"
              phx-hook="CopyText"
              data-text={@output}
              class="px-4 py-2 rounded border border-border bg-secondary text-foreground text-xs font-mono hover:bg-secondary/80 transition-colors"
            >
              copy
            </button>
          </div>
        </form>
      </.col>
    </.dashboard_layout>
    """
  end
end
