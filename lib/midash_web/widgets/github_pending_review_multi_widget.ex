defmodule MidashWeb.Widgets.GithubPendingReviewMultiWidget do
  @moduledoc """
  Shows pending-review PRs for multiple repos with one tab per repo.

  Required assigns:
  - `repos` - list of "owner/repo" strings
  - `token` - GitHub personal access token
  - `me`    - your GitHub username (to check approval)
  """
  use MidashWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, repos_data: %{}, loading: true)}
  end

  @impl true
  def update(%{action: :fetch}, socket) do
    {:ok, fetch_all(socket)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket = assign_new(socket, :active_tab, fn -> List.first(assigns.repos) end)

    if connected?(socket) do
      send(self(), {:fetch_pending_review_multi, socket.assigns.id})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"repo" => repo}, socket) do
    {:noreply, assign(socket, active_tab: repo)}
  end

  def handle_event("filter_author", %{"author" => author, "repo" => repo}, socket) do
    repos_data =
      Map.update!(socket.assigns.repos_data, repo, &Map.put(&1, :author_filter, author))

    {:noreply, assign(socket, repos_data: repos_data)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Tab bar --%>
      <div class="flex gap-1 mb-3 border-b border-border">
        <%= for repo <- @repos do %>
          <% active = @active_tab == repo %>
          <button
            phx-click="switch_tab"
            phx-value-repo={repo}
            phx-target={@myself}
            class={[
              "px-3 py-1 text-xs font-mono transition-colors",
              if(active, do: "text-foreground border-b-2 border-foreground -mb-px", else: "text-muted-foreground hover:text-foreground")
            ]}
          >
            {repo_name(repo)}
          </button>
        <% end %>
      </div>

      <%!-- Tab content --%>
      <div :if={@loading} class="text-muted-foreground text-sm py-2">fetching...</div>
      <%= if !@loading do %>
        <% data = Map.get(@repos_data, @active_tab, %{prs: [], authors: [], author_filter: "all", error: nil}) %>
        <div :if={data[:error]} class="text-destructive text-sm">{data[:error]}</div>
        <div :if={!data[:error]}>
          <div :if={data.prs != []} class="mb-2 flex items-center justify-end gap-2">
            <label class="text-muted-foreground text-xs">author:</label>
            <form phx-change="filter_author" phx-target={@myself} class="flex items-center">
              <input type="hidden" name="repo" value={@active_tab} />
              <select
                name="author"
                class="bg-secondary border border-border rounded text-xs px-2 py-1 pr-6 text-foreground cursor-pointer appearance-none"
              >
                <option value="all" selected={data.author_filter == "all"}>all</option>
                <%= for author <- data.authors do %>
                  <option value={author} selected={data.author_filter == author}>@{author}</option>
                <% end %>
              </select>
            </form>
          </div>
          <% filtered = filtered_prs(data.prs, data.author_filter) %>
          <div :if={filtered == []} class="text-muted-foreground text-sm">no prs need review</div>
          <div :if={filtered != []} class="space-y-3">
            <%= for pr <- filtered do %>
              <div class="border-l-2 border-border pl-3">
                <a
                  href={pr["html_url"]}
                  target="_blank"
                  class="text-sm text-info hover:underline block mb-1"
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
      <% end %>
    </div>
    """
  end

  defp filtered_prs(prs, "all"), do: prs
  defp filtered_prs(prs, author), do: Enum.filter(prs, &(&1["author"] == author))

  defp fetch_all(socket) do
    token = socket.assigns.token
    me = socket.assigns.me

    repos_data =
      socket.assigns.repos
      |> Enum.map(fn repo ->
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
            {repo, %{prs: pending, authors: authors, author_filter: "all", error: nil}}

          {:error, reason} ->
            {repo, %{prs: [], authors: [], author_filter: "all", error: reason}}
        end
      end)
      |> Map.new()

    socket = assign(socket, repos_data: repos_data, loading: false)
    push_event(socket, "refresh_done", %{id: socket.assigns.id})
  end

  defp repo_name(repo), do: repo |> String.split("/") |> List.last()

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
