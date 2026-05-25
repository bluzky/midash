defmodule MidashWeb.WorkLive do
  use MidashWeb, :live_view

  alias MidashWeb.Widgets.{
    GithubPrsMultiWidget,
    GithubPendingReviewMultiWidget,
    GithubMyPrsMultiWidget,
    ClickupTaskCountWidget,
    ClickupTaskListWidget,
    QuickNoteWidget
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       github_token: System.get_env("GITHUB_TOKEN", ""),
       clickup_token: System.get_env("CLICKUP_TOKEN", ""),
       github_username: System.get_env("GITHUB_USERNAME", "bluzky"),
       clickup_team_id: System.get_env("CLICKUP_TEAM_ID", "9018975210"),
       clickup_user_id: System.get_env("CLICKUP_USER_ID", "95668281")
     ), layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("refresh", %{"id" => id, "module" => module}, socket) do
    send_update(String.to_existing_atom(module), id: id, action: :fetch)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:fetch_github_prs_multi, id}, socket) do
    send_update(GithubPrsMultiWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  def handle_info({:fetch_pending_review_multi, id}, socket) do
    send_update(GithubPendingReviewMultiWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  def handle_info({:fetch_my_prs_multi, id}, socket) do
    send_update(GithubMyPrsMultiWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  def handle_info({:fetch_clickup_task_count, id}, socket) do
    send_update(ClickupTaskCountWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  def handle_info({:fetch_clickup_task_list, id}, socket) do
    send_update(ClickupTaskListWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout current={MidashWeb.Nav.current_from_module(__MODULE__)}>
      <%!-- Left column: GitHub PRs --%>
      <.col span={4}>
        <.widget
          id="w-all-prs"
          title="pr by dev"
          on_refresh={JS.push("refresh", value: %{id: "work-all-pr-by-dev", module: "Elixir.MidashWeb.Widgets.GithubPrsMultiWidget"})}
          collapsible
        >
          <.live_component
            module={GithubPrsMultiWidget}
            id="work-all-pr-by-dev"
            repos={["innoshiftco/innosync", "innoshiftco/innoup", "innoshiftco/innowa"]}
            token={@github_token}
          />
        </.widget>

        <.widget
          id="w-my-prs"
          title="my prs"
          on_refresh={JS.push("refresh", value: %{id: "work-my-prs", module: "Elixir.MidashWeb.Widgets.GithubMyPrsMultiWidget"})}
          collapsible
        >
          <.live_component
            module={GithubMyPrsMultiWidget}
            id="work-my-prs"
            repos={["innoshiftco/innoup", "innoshiftco/innosync", "innoshiftco/innowa"]}
            token={@github_token}
            me={@github_username}
          />
        </.widget>

        <.widget
          id="w-pending-review"
          title="pending review"
          on_refresh={JS.push("refresh", value: %{id: "work-pending-review", module: "Elixir.MidashWeb.Widgets.GithubPendingReviewMultiWidget"})}
          collapsible
        >
          <.live_component
            module={GithubPendingReviewMultiWidget}
            id="work-pending-review"
            repos={["innoshiftco/innoup", "innoshiftco/innosync", "innoshiftco/innowa"]}
            token={@github_token}
            me={@github_username}
          />
        </.widget>

      </.col>

      <%!-- Center column: ClickUp tasks --%>
      <.col span={4}>
        <.widget
          id="w-clickup-count"
          title="task count"
          on_refresh={JS.push("refresh", value: %{id: "work-clickup-task-count", module: "Elixir.MidashWeb.Widgets.ClickupTaskCountWidget"})}
          collapsible
        >
          <.live_component
            module={ClickupTaskCountWidget}
            id="work-clickup-task-count"
            token={@clickup_token}
            team_id={@clickup_team_id}
            user_id={@clickup_user_id}
          />
        </.widget>

        <.widget
          id="w-clickup-tasks"
          title="my tasks"
          on_refresh={JS.push("refresh", value: %{id: "work-clickup-task-list", module: "Elixir.MidashWeb.Widgets.ClickupTaskListWidget"})}
          collapsible
        >
          <.live_component
            module={ClickupTaskListWidget}
            id="work-clickup-task-list"
            token={@clickup_token}
            team_id={@clickup_team_id}
            user_id={@clickup_user_id}
          />
        </.widget>
      </.col>

      <%!-- Rightmost column: notes --%>
      <.col span={4}>
        <.widget id="w-quick-note" title="quick note">
          <.live_component module={QuickNoteWidget} id="work-quick-note" />
        </.widget>
      </.col>
    </.dashboard_layout>
    """
  end
end
