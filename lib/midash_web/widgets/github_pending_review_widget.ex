defmodule MidashWeb.Widgets.GithubPendingReviewWidget do
  @moduledoc """
  Shows open PRs that the given user has NOT yet approved.

  Required assigns:
  - `repo`      - "owner/repo" string
  - `token`     - GitHub personal access token
  - `me`        - your GitHub username (to check approval)
  - `base`      - base branch (default "staging")
  """
  use MidashWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, prs: [], loading: true, error: nil)}
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

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@loading} class="text-muted-foreground text-xs py-2">fetching...</div>
      <div :if={@error} class="text-destructive text-xs py-2">{@error}</div>
      <div :if={!@loading && !@error}>
        <div :if={@prs == []} class="text-muted-foreground text-xs">no prs need review</div>
        <div :if={@prs != []} class="space-y-3">
          <%= for pr <- @prs do %>
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

  defp fetch_pending(socket) do
    repo = socket.assigns.repo
    token = socket.assigns.token
    me = socket.assigns.me
    base = Map.get(socket.assigns, :base, "staging")
    [owner, repo_name] = String.split(repo, "/")

    case Midash.GitHub.fetch_open_prs(token, owner, repo_name, base) do
      {:ok, prs} ->
        pending =
          prs
          |> Enum.map(fn pr ->
            reviews = pr["reviews"]
            approved_by = reviews |> Enum.filter(&(&1["state"] == "APPROVED")) |> Enum.map(& &1["author"])
            i_approved = me in approved_by
            i_requested = me in pr["review_requestees"]
            targets_base = pr["base_ref"] == base
            Map.merge(pr, %{i_approved: i_approved, approvals: length(approved_by), i_requested: i_requested, targets_base: targets_base})
          end)
          |> Enum.reject(fn pr -> pr["author"] == me end)
          |> Enum.filter(fn pr -> pr.targets_base or pr.i_requested end)
          |> Enum.reject(fn pr -> pr.i_approved end)

        assign(socket, prs: pending, loading: false, error: nil)

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
