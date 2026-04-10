defmodule MidashWeb.Widgets.GithubPendingReviewWidget do
  @moduledoc """
  Shows open PRs that the given user has NOT yet approved, excluding those targeting develop.

  Required assigns:
  - `repo`      - "owner/repo" string
  - `token`     - GitHub personal access token
  - `me`        - your GitHub username (to check approval)
  """
  use MidashWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, prs: [], loading: true, error: nil, author_filter: "all", authors: [])}
  end

  @impl true
  def update(%{action: :fetch}, socket) do
    {:ok, fetch_pending(socket)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if connected?(socket) do
      send(self(), {:fetch_pending_review, socket.assigns.id})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("refresh", _, socket) do
    {:noreply, socket |> assign(loading: true) |> fetch_pending()}
  end

  def handle_event("filter_author", %{"author" => author}, socket) do
    {:noreply, assign(socket, author_filter: author)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@loading} class="text-muted-foreground text-xs py-2">fetching...</div>
      <div :if={@error} class="text-destructive text-xs py-2">{@error}</div>
      <div :if={!@loading && !@error}>
        <div :if={@prs != []} class="mb-2 flex items-center justify-end gap-2">
          <label for={"author-select-#{@id}"} class="text-muted-foreground text-xs">author:</label>
          <form phx-change="filter_author" phx-target={@myself} class="flex items-center">
            <select
              id={"author-select-#{@id}"}
              name="author"
              class="bg-secondary border border-border rounded text-xs px-2 py-1 pr-6 text-foreground cursor-pointer appearance-none bg-no-repeat bg-right"
            >
              <option value="all" selected={@author_filter == "all"}>all</option>
              <%= for author <- @authors do %>
                <option value={author} selected={@author_filter == author}>@{author}</option>
              <% end %>
            </select>
          </form>
        </div>
        <div :if={filtered_prs(@prs, @author_filter) == []} class="text-muted-foreground text-xs">no prs need review</div>
        <div :if={filtered_prs(@prs, @author_filter) != []} class="space-y-3">
          <%= for pr <- filtered_prs(@prs, @author_filter) do %>
            <div class="border-l-2 border-border pl-3">
              <a
                href={pr["html_url"]}
                target="_blank"
                class="text-xs text-info hover:underline block mb-1"
              >
                <span class="text-muted-foreground">#<%= pr["number"] %></span>
                {pr["title"]}
              </a>
              <div class="flex gap-3 text-xs text-muted-foreground">
                <span>@{pr["author"]}</span>
                <span>+{pr[:approvals]} approvals</span>
                <span>{relative_time(pr["created_at"])}</span>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp filtered_prs(prs, "all"), do: prs
  defp filtered_prs(prs, author), do: Enum.filter(prs, &(&1["author"] == author))

  defp fetch_pending(socket) do
    repo = socket.assigns.repo
    token = socket.assigns.token
    me = socket.assigns.me
    [owner, repo_name] = String.split(repo, "/")

    case Midash.GitHub.fetch_open_prs(token, owner, repo_name) do
      {:ok, prs} ->
        pending =
          prs
          |> Enum.map(fn pr ->
            reviews = pr["reviews"]
            approved_by = reviews |> Enum.filter(&(&1["state"] == "APPROVED")) |> Enum.map(& &1["author"])
            i_approved = me in approved_by
            Map.merge(pr, %{i_approved: i_approved, approvals: length(approved_by)})
          end)
          |> Enum.reject(fn pr -> pr["author"] == me end)
          |> Enum.filter(fn pr -> pr["base_ref"] != "develop" and not pr.i_approved end)

        authors = pending |> Enum.map(& &1["author"]) |> Enum.uniq() |> Enum.sort()
        assign(socket, prs: pending, authors: authors, loading: false, error: nil)

      {:error, reason} ->
        assign(socket, loading: false, error: reason)
    end
  end

  defp relative_time(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} ->
        diff = DateTime.diff(DateTime.utc_now(), dt, :hour)

        cond do
          diff < 1 -> "just now"
          diff < 24 -> "#{diff}h ago"
          true -> "#{div(diff, 24)}d ago"
        end

      _ ->
        iso
    end
  end
end
