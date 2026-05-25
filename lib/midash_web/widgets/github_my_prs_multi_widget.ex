defmodule MidashWeb.Widgets.GithubMyPrsMultiWidget do
  @moduledoc """
  Shows my open PRs for multiple repos with one tab per repo.

  Required assigns:
  - `repos` - list of "owner/repo" strings
  - `token` - GitHub personal access token
  - `me`    - your GitHub username
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
      send(self(), {:fetch_my_prs_multi, socket.assigns.id})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("switch_tab", %{"repo" => repo}, socket) do
    {:noreply, assign(socket, active_tab: repo)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%!-- Tab bar --%>
      <div class="flex gap-1 mb-3 border-b border-border">
        <%= for repo <- @repos do %>
          <% name = repo_name(repo) %>
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
            {name}
          </button>
        <% end %>
      </div>

      <%!-- Tab content --%>
      <div :if={@loading} class="text-muted-foreground text-sm py-2">fetching...</div>
      <%= if !@loading do %>
        <% data = Map.get(@repos_data, @active_tab, %{prs: [], error: nil}) %>
        <div :if={data[:error]} class="text-destructive text-sm">{data[:error]}</div>
        <div :if={!data[:error]}>
          <div :if={data.prs == []} class="text-muted-foreground text-sm">no open prs</div>
          <div :if={data.prs != []} class="space-y-3">
            <%= for pr <- data.prs do %>
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
                  <span class="text-warning">{pr[:approvals]} approvals</span>
                  <span>{relative_time(pr["created_at"])}</span>
                </div>
                <div :if={pr["head_ref"]} class="flex items-center gap-1 mt-1">
                  <span class="text-xs text-muted-foreground font-mono truncate">{pr["head_ref"]}</span>
                  <button
                    type="button"
                    class="text-muted-foreground hover:text-foreground transition-colors shrink-0"
                    title="Copy branch name"
                    phx-hook="CopyToClipboard"
                    id={"copy-branch-#{pr["number"]}"}
                    data-copy={pr["head_ref"]}
                  >
                    <Lucideicons.clipboard class="w-3 h-3" />
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp fetch_all(socket) do
    token = socket.assigns.token
    me = socket.assigns.me

    repos_data =
      socket.assigns.repos
      |> Enum.map(fn repo ->
        [owner, repo_name] = String.split(repo, "/")

        case Midash.GitHub.fetch_open_prs(token, owner, repo_name) do
          {:ok, prs} ->
            my_prs =
              prs
              |> Enum.filter(fn pr -> pr["author"] == me and pr["base_ref"] != "develop" end)
              |> Enum.map(fn pr ->
                approval_count = Enum.count(pr["reviews"], &(&1["state"] == "APPROVED"))
                Map.put(pr, :approvals, approval_count)
              end)

            {repo, %{prs: my_prs, error: nil}}

          {:error, reason} ->
            {repo, %{prs: [], error: reason}}
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
