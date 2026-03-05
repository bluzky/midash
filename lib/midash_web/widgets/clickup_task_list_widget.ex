defmodule MidashWeb.Widgets.ClickupTaskListWidget do
  @moduledoc """
  Shows task list grouped by status.

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
      send(self(), {:fetch_clickup_task_list, socket.assigns.id})
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
        <%= for s <- @statuses do %>
          <% status_tasks = Clickup.filter_by_status(@tasks, s.key) %>
          <div :if={status_tasks != []} class="mb-4">
            <div class="text-xs uppercase tracking-widest mb-2" style={"color: #{s.color}"}>
              {s.label}
            </div>
            <div class="space-y-1">
              <%= for task <- status_tasks do %>
                <div class="flex items-start gap-2">
                  <span class="text-border text-xs shrink-0 mt-0.5">—</span>
                  <a
                    href={task["url"]}
                    target="_blank"
                    class="text-xs text-foreground hover:text-foreground/90 hover:underline leading-snug"
                  >
                    {task["name"]}
                  </a>
                  <span :if={task["due_date"]} class="text-muted-foreground text-xs shrink-0 ml-auto">
                    {Clickup.format_due(task["due_date"])}
                  </span>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <div :if={@tasks == []} class="text-muted-foreground text-xs">no tasks</div>
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
