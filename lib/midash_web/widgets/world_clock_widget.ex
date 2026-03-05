defmodule MidashWeb.Widgets.WorldClockWidget do
  @moduledoc """
  Displays current time for a list of cities/timezones, updating every second.

  Required assigns:
  - `clocks` - list of `%{label: string, tz: string}` e.g.
      [%{label: "Phoenix", tz: "America/Phoenix"}, ...]
  """
  use MidashWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, times: [])}
  end

  @impl true
  def update(assigns, socket) do
    if connected?(socket) do
      Process.send_after(self(), {:world_clock_tick, assigns.id}, 1000)
    end

    socket = assign(socket, assigns)
    clocks = socket.assigns[:clocks] || []
    {:ok, assign(socket, times: current_times(clocks))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-3">
      <%= for {clock, time} <- Enum.zip(@clocks, @times) do %>
        <div class="flex items-baseline justify-between gap-2">
          <span class="text-xs text-muted-foreground truncate">{clock.label}</span>
          <span class="text-sm tabular-nums text-foreground font-mono tracking-tight">{time}</span>
        </div>
      <% end %>
    </div>
    """
  end

  defp current_times(clocks) do
    Enum.map(clocks, fn clock ->
      case DateTime.now(clock.tz) do
        {:ok, dt} -> Calendar.strftime(dt, "%I:%M %p")
        _ -> "--:-- --"
      end
    end)
  end
end
