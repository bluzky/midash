defmodule MidashWeb.Widgets.GithubPrsWidget do
  @moduledoc """
  Shows open PRs grouped by author for a GitHub repo.

  Required assigns:
  - `repo`  - "owner/repo" string
  - `token` - GitHub personal access token
  - `base`  - base branch (default "staging")
  """
  use MidashWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, prs: [], loading: true, error: nil)}
  end

  @impl true
  def update(%{action: :fetch}, socket) do
    {:ok, fetch_prs(socket)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if connected?(socket) do
      send(self(), {:fetch_github_prs, socket.assigns.id})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("refresh", _, socket) do
    {:noreply, socket |> assign(loading: true) |> fetch_prs()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@loading} class="text-muted-foreground text-xs py-2">fetching...</div>
      <div :if={@error} class="text-destructive text-xs py-2">{@error}</div>
      <div :if={!@loading && !@error}>
        <div :if={@prs == []} class="text-muted-foreground text-xs">no open prs</div>
        <div :if={@prs != []} class="flex flex-wrap gap-3">
          <%= for {author, count} <- pr_by_author(@prs) do %>
            <a
              href={"https://github.com/#{@repo}/pulls?q=is:pr+is:open+author:#{author}+base:#{@base}"}
              target="_blank"
              class="flex flex-col items-center rounded-md border border-border px-3 py-2 hover:bg-secondary transition-colors min-w-16"
            >
              <span class="text-xs text-muted-foreground">{author}</span>
              <span class="text-xl text-success tabular-nums">{count}</span>
            </a>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp fetch_prs(socket) do
    repo = socket.assigns.repo
    token = socket.assigns.token
    base = Map.get(socket.assigns, :base, "staging")
    [owner, repo_name] = String.split(repo, "/")

    case Midash.GitHub.fetch_open_prs(token, owner, repo_name, base) do
      {:ok, prs} -> assign(socket, prs: prs, loading: false, error: nil)
      {:error, reason} -> assign(socket, loading: false, error: reason)
    end
  end

  defp pr_by_author(prs) do
    prs
    |> Enum.group_by(& &1["author"])
    |> Enum.map(fn {author, list} -> {author, length(list)} end)
    |> Enum.sort_by(fn {_, count} -> -count end)
  end
end
