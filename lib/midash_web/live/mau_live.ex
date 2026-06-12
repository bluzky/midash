defmodule MidashWeb.MauLive do
  use MidashWeb, :live_view

  @default_template "Hello, {{ name }}!\n\n{% if items %}\nItems:\n{% for item in items %}\n- {{ item | upper_case }}\n{% endfor %}\n{% endif %}"

  @default_params ~s({\n  "name": "World",\n  "items": ["apple", "banana", "cherry"]\n})

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       template: @default_template,
       params: @default_params,
       output: nil,
       error: nil
     ),
     layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("run", %{"template" => template, "params" => params}, socket) do
    case Jason.decode(params) do
      {:ok, context} ->
        case Mau.render(template, context) do
          {:ok, result} ->
            {:noreply, assign(socket, output: result, error: nil)}

          {:error, err} ->
            {:noreply, assign(socket, error: Kernel.inspect(err), output: nil)}
        end

      {:error, %Jason.DecodeError{} = err} ->
        {:noreply, assign(socket, error: "Invalid JSON: #{Exception.message(err)}", output: nil)}
    end
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
          <span class="text-xs text-foreground font-mono">mau template</span>
        </div>

        <form phx-submit="run" class="flex flex-col gap-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col gap-1">
              <label class="text-xs text-muted-foreground uppercase tracking-widest">Template</label>
              <textarea
                name="template"
                class="h-72 w-full rounded border border-border bg-background p-3 font-mono text-sm text-foreground resize-none focus:outline-none focus:ring-1 focus:ring-ring"
                placeholder="Enter Mau template..."
                spellcheck="false"
              ><%= @template %></textarea>
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-xs text-muted-foreground uppercase tracking-widest">
                Params <span class="normal-case">(JSON)</span>
              </label>
              <textarea
                name="params"
                class="h-72 w-full rounded border border-border bg-background p-3 font-mono text-sm text-foreground resize-none focus:outline-none focus:ring-1 focus:ring-ring"
                placeholder='{"key": "value"}'
                spellcheck="false"
              ><%= @params %></textarea>
            </div>
          </div>

          <div>
            <button
              type="submit"
              class="px-4 py-2 rounded border border-border bg-secondary text-foreground text-xs font-mono hover:bg-secondary/80 transition-colors"
            >
              render
            </button>
          </div>

          <div :if={not is_nil(@output) or not is_nil(@error)} class="flex flex-col gap-1">
            <label class="text-xs text-muted-foreground uppercase tracking-widest">Output</label>
            <pre class={[
              "rounded border border-border p-3 text-xs font-mono overflow-auto whitespace-pre-wrap",
              if(@error, do: "bg-destructive/10 text-destructive", else: "bg-secondary text-green-400")
            ]}>{if @error, do: @error, else: @output}</pre>
          </div>
        </form>
      </.col>
    </.dashboard_layout>
    """
  end
end
