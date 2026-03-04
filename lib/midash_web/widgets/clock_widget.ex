defmodule MidashWeb.Widgets.ClockWidget do
  use MidashWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, time: current_time(), date: current_date())}
  end

  @impl true
  def update(assigns, socket) do
    if connected?(socket) do
      Process.send_after(self(), {:clock_tick, assigns.id}, 1000)
    end

    {:ok, assign(socket, assigns) |> assign(time: current_time(), date: current_date())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-center py-2">
      <div class="text-3xl font-mono tabular-nums text-gray-100 tracking-tight">
        {@time}
      </div>
      <div class="text-xs text-gray-600 mt-1">
        {@date}
      </div>
    </div>
    """
  end

  defp current_time do
    Time.utc_now() |> Time.truncate(:second) |> to_string()
  end

  defp current_date do
    Date.utc_today() |> Calendar.strftime("%Y-%m-%d %A")
  end
end
