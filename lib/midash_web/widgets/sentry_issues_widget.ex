defmodule MidashWeb.Widgets.SentryIssuesWidget do
  @moduledoc """
  Shows top 10 Sentry issues from the last 24 hours.

  Required assigns:
  - `org_slug` - Sentry organization slug (e.g., "gdec")
  - `project_slug` - Sentry project slug (e.g., "oms")
  - `environment` - Optional environment filter (e.g., "gdec-prod", "gdec-dev")
  """
  use MidashWeb, :live_component

  alias Midash.Sentry

  @impl true
  def mount(socket) do
    {:ok, assign(socket, issues: [], loading: true, error: nil, sort: "freq")}
  end

  @impl true
  def update(%{action: :fetch}, socket) do
    {:ok, fetch_issues(socket)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if connected?(socket) do
      send(self(), {:fetch_sentry_issues, socket.assigns.id})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("refresh", _, socket) do
    {:noreply, socket |> assign(loading: true) |> fetch_issues()}
  end

  def handle_event("change_sort", %{"sort" => sort}, socket) do
    {:noreply, socket |> assign(sort: sort, loading: true) |> fetch_issues()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={!@loading && !@error} class="mb-2 flex items-center justify-end gap-2">
        <label for={"sort-select-#{@id}"} class="text-muted-foreground text-xs">sort:</label>
        <form phx-change="change_sort" phx-target={@myself} class="flex items-center">
          <select
            id={"sort-select-#{@id}"}
            name="sort"
            class="bg-secondary border border-border rounded text-xs px-2 py-1 pr-6 text-foreground cursor-pointer appearance-none bg-no-repeat bg-right"
          >
            <option value="freq" selected={@sort == "freq"}>highest events</option>
            <option value="date" selected={@sort == "date"}>last seen</option>
            <option value="user" selected={@sort == "user"}>affected users</option>
            <option value="new" selected={@sort == "new"}>first seen</option>
            <option value="trends" selected={@sort == "trends"}>rising issues</option>
          </select>
        </form>
      </div>
      <div :if={@loading} class="text-muted-foreground text-xs py-2">fetching...</div>
      <div :if={!@loading}>
        <div :if={@issues == []} class="text-muted-foreground text-xs">no issues in 24h</div>
        <div :if={@issues != []} class="text-xs w-full">
          <table class="w-full table-fixed">
            <thead>
              <tr class="border-b border-border text-muted-foreground text-[11px]">
                <th class="text-left py-1 px-0 font-normal">title</th>
                <th class="text-right py-1 px-0 font-normal w-16">last seen</th>
                <th class="text-right py-1 px-0 font-normal w-20">events</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-border">
              <%= for issue <- @issues do %>
                <% count = String.to_integer(to_string(issue["count"])) %>
                <% highlight = count > 1000 %>
                <tr class="hover:bg-secondary transition-colors">
                  <td class="py-1 px-0 min-w-0">
                    <a
                      href={issue["url"]}
                      target="_blank"
                      title={issue["title"]}
                      class={[
                        "block truncate underline",
                        highlight && "text-destructive font-semibold",
                        !highlight && "text-foreground"
                      ]}
                    >
                      {issue["title"]}
                    </a>
                  </td>
                  <td class="py-1 px-0 text-right text-muted-foreground text-[11px] w-16 shrink-0">
                    {format_date(issue["lastSeen"])}
                  </td>
                  <td class="py-1 px-0 text-right w-20 shrink-0">
                    <div class={[
                      "bg-secondary/50 text-foreground px-2 py-0.5 rounded text-[11px] font-mono font-semibold tabular-nums inline-block",
                      highlight && "text-destructive"
                    ]}>
                      {format_count(count)}
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp format_count(count) do
    cond do
      count >= 1_000_000 ->
        millions = count / 1_000_000
        "#{Float.round(millions, 1)}M"

      count >= 1000 ->
        thousands = count / 1000
        "#{Float.round(thousands, 1)}K"

      true ->
        to_string(count)
    end
  end

  defp format_date(iso_string) do
    case DateTime.from_iso8601(iso_string) do
      {:ok, datetime, _offset} ->
        now = DateTime.utc_now()
        seconds_ago = DateTime.diff(now, datetime)

        cond do
          seconds_ago < 60 -> "now"
          seconds_ago < 3600 -> "#{div(seconds_ago, 60)}m ago"
          seconds_ago < 86400 -> "#{div(seconds_ago, 3600)}h ago"
          seconds_ago < 604_800 -> "#{div(seconds_ago, 86400)}d ago"
          true -> "#{div(seconds_ago, 604_800)}w ago"
        end

      _ ->
        "—"
    end
  end

  defp fetch_issues(socket) do
    org_slug = socket.assigns.org_slug
    project_slug = socket.assigns.project_slug
    environment = Map.get(socket.assigns, :environment, nil)
    sort = socket.assigns.sort

    # Build filters for last 24 hours
    filters = %{
      "query" => "lastSeen:>=#{yesterday_iso()}"
    }

    filters =
      if environment, do: Map.put(filters, "environment", environment), else: filters

    case Sentry.fetch_issues(org_slug, project_slug, filters, sort: sort) do
      {:ok, issues} ->
        assign(socket, issues: issues, loading: false, error: nil)

      {:error, reason} ->
        assign(socket, loading: false, error: reason)
    end
  end

  defp yesterday_iso do
    DateTime.utc_now()
    |> DateTime.add(-86400, :second)
    |> DateTime.to_iso8601()
    |> String.slice(0..9)
  end
end
