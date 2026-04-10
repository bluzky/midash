defmodule MidashWeb.ElixirExecuteLive do
  use MidashWeb, :live_view

  @starter_code "# `input` is available as a variable\n# Example: String.upcase(input)\ninput\n"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, input: "", output: nil, error: nil, starter_code: @starter_code),
     layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("update_input", %{"value" => value}, socket) do
    {:noreply, assign(socket, input: value)}
  end

  @impl true
  def handle_event("run", %{"code" => code}, socket) do
    case run_code(socket.assigns.input, code) do
      {:ok, result} -> {:noreply, assign(socket, output: result, error: nil)}
      {:error, message} -> {:noreply, assign(socket, error: message, output: nil)}
    end
  end

  defp run_code(input, code) do
    binding = [input: input]
    {result, _binding} = Code.eval_string(code, binding)
    {:ok, Kernel.inspect(result)}
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
          <span class="text-xs text-foreground font-mono">elixir execute</span>
        </div>

        <div class="flex flex-col gap-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col gap-1">
              <label class="text-xs text-muted-foreground uppercase tracking-widest">Input</label>
              <form phx-change="update_input">
                <textarea
                  class="h-64 w-full rounded border border-border bg-background p-3 font-mono text-sm text-foreground resize-none focus:outline-none focus:ring-1 focus:ring-ring"
                  placeholder="Enter input string..."
                  name="value"
                  phx-debounce="blur"
                >{@input}</textarea>
              </form>
            </div>
            <div class="flex flex-col gap-1">
              <label class="text-xs text-muted-foreground uppercase tracking-widest">Code</label>
              <div
                id="elixir-execute-codejar"
                phx-hook="CodeJarHook"
                phx-update="ignore"
                data-code={@starter_code}
                class="h-64 w-full rounded border border-border bg-background p-3 font-mono text-sm text-foreground overflow-auto focus:outline-none focus:ring-1 focus:ring-ring"
              ></div>
            </div>
          </div>

          <div>
            <button
              id="elixir-execute-run-btn"
              phx-hook="RunButtonHook"
              data-editor-id="elixir-execute-codejar"
              class="px-4 py-2 rounded border border-border bg-secondary text-foreground text-xs font-mono hover:bg-secondary/80 transition-colors"
            >
              run
            </button>
          </div>

          <div :if={not is_nil(@output) or not is_nil(@error)} class="flex flex-col gap-1">
            <label class="text-xs text-muted-foreground uppercase tracking-widest">Output</label>
            <pre class={[
              "rounded border border-border p-3 text-xs font-mono overflow-auto whitespace-pre-wrap",
              if(@error, do: "bg-destructive/10 text-destructive", else: "bg-secondary text-green-400")
            ]}>{if @error, do: @error, else: @output}</pre>
          </div>
        </div>
      </.col>
    </.dashboard_layout>
    """
  end
end
