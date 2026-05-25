defmodule MidashWeb.Widgets.GithubPrsMultiWidget do
  @moduledoc """
  Shows open PRs grouped by author for multiple GitHub repos, one repo per row.

  Required assigns:
  - `repos` - list of "owner/repo" strings
  - `token` - GitHub personal access token
  """
  use MidashWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, repos_data: %{}, loading: true, error: nil)}
  end

  @impl true
  def update(%{action: :fetch}, socket) do
    {:ok, fetch_all_prs(socket)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if connected?(socket) do
      send(self(), {:fetch_github_prs_multi, socket.assigns.id})
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-3">
      <div :if={@loading} class="text-muted-foreground text-sm py-2">fetching...</div>
      <div :if={@error} class="text-destructive text-sm py-2">{@error}</div>
      <%= for repo <- @repos do %>
        <% data = Map.get(@repos_data, repo, %{loading: true, prs: [], error: nil}) %>
        <div class="flex flex-col gap-1">
          <span class="text-xs text-muted-foreground font-mono">{repo_name(repo)}</span>
          <div :if={data.loading} class="text-muted-foreground text-sm">fetching...</div>
          <div :if={data[:error]} class="text-destructive text-sm">{data[:error]}</div>
          <div :if={!data.loading && !data[:error]}>
            <div :if={data.prs == []} class="text-muted-foreground text-sm">no open prs</div>
            <div :if={data.prs != []} class="flex flex-wrap gap-2">
              <%= for {author, count} <- pr_by_author(data.prs) do %>
                <a
                  href={"https://github.com/#{repo}/pulls?q=is:pr+is:open+author:#{author}"}
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
      <% end %>
    </div>
    """
  end

  defp fetch_all_prs(socket) do
    token = socket.assigns.token

    repos_data =
      socket.assigns.repos
      |> Enum.map(fn repo ->
        [owner, repo_name] = String.split(repo, "/")

        case Midash.GitHub.fetch_open_prs(token, owner, repo_name) do
          {:ok, prs} ->
            filtered = Enum.filter(prs, fn pr -> pr["base_ref"] != "develop" end)
            {repo, %{loading: false, prs: filtered, error: nil}}

          {:error, reason} ->
            {repo, %{loading: false, prs: [], error: reason}}
        end
      end)
      |> Map.new()

    socket = assign(socket, repos_data: repos_data, loading: false, error: nil)
    push_event(socket, "refresh_done", %{id: socket.assigns.id})
  end

  defp pr_by_author(prs) do
    prs
    |> Enum.group_by(& &1["author"])
    |> Enum.map(fn {author, list} -> {author, length(list)} end)
    |> Enum.sort_by(fn {_, count} -> -count end)
  end

  defp repo_name(repo), do: repo |> String.split("/") |> List.last()
end
