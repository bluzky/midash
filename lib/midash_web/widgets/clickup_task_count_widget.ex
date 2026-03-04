defmodule MidashWeb.Widgets.ClickupTaskCountWidget do
  @moduledoc """
  Shows task count badges grouped by status.

  Required assigns:
  - `token`   - ClickUp API token
  - `team_id` - ClickUp team/workspace ID
  - `user_id` - ClickUp user ID to filter tasks by assignee
  """
  use MidashWeb, :live_component

  alias Midash.Clickup

  @statuses Clickup.statuses()

  @impl true
  def mount(socket) do
    {:ok, assign(socket, tasks: [], loading: true, error: nil)}
  end

  @impl true
  def update(%{action: :fetch}, socket) do
    {:ok, fetch_tasks(socket)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if connected?(socket) do
      send(self(), {:fetch_clickup_task_count, socket.assigns.id})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("refresh", _, socket) do
    {:noreply, socket |> assign(loading: true) |> fetch_tasks()}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :statuses, @statuses)

    ~H"""
    <div>
      <div :if={@loading} class="text-muted-foreground text-xs py-2">fetching...</div>
      <div :if={@error} class="text-destructive text-xs py-2">{@error}</div>
      <div :if={!@loading && !@error}>
        <div class="flex gap-2 flex-wrap">
          <%= for s <- @statuses do %>
            <% count = Clickup.count_by_status(@tasks, s.key) %>
            <div class="border border-border px-3 py-2 text-center min-w-20">
              <div class="text-xs text-muted-foreground">{s.label}</div>
              <div class="text-2xl tabular-nums" style={"color: #{s.color}"}>{count}</div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp fetch_tasks(socket) do
    case Clickup.fetch_tasks(socket.assigns.token, socket.assigns.team_id, socket.assigns.user_id) do
      {:ok, tasks} -> assign(socket, tasks: tasks, loading: false, error: nil)
      {:error, msg} -> assign(socket, loading: false, error: msg)
    end
  end
end
