defmodule MidashWeb.WorkLive do
  use MidashWeb, :live_view

  alias MidashWeb.Widgets.{
    GithubPrsWidget,
    GithubPendingReviewWidget,
    GithubMyPrsWidget,
    ClickupTaskCountWidget,
    ClickupTaskListWidget,
    QuickNoteWidget
  }

  @nav_pages [
    %{id: :home, label: "home", path: "/"},
    %{id: :work, label: "work", path: "/work"},
    %{id: :monitor, label: "monitor", path: "/monitor"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       nav_pages: @nav_pages,
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
  def handle_info({:fetch_github_prs, id}, socket) do
    send_update(GithubPrsWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  def handle_info({:fetch_pending_review, id}, socket) do
    send_update(GithubPendingReviewWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  def handle_info({:fetch_my_prs, id}, socket) do
    send_update(GithubMyPrsWidget, id: id, action: :fetch)
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
    <.dashboard_layout nav_pages={@nav_pages} current={:work}>
      <%!-- Left column: GitHub PRs --%>
      <.col span={4}>
        <.widget
          id="w-innosync-prs"
          title="innosync — pr by dev"
          on_refresh={JS.push("refresh", value: %{id: "work-innosync-pr-by-dev", module: "Elixir.MidashWeb.Widgets.GithubPrsWidget"})}
          collapsible
        >
          <.live_component
            module={GithubPrsWidget}
            id="work-innosync-pr-by-dev"
            repo="innoshiftco/innosync"
            token={@github_token}
            base="staging"
          />
        </.widget>

        <.widget
          id="w-innoup-prs"
          title="innoup — pr by dev"
          on_refresh={JS.push("refresh", value: %{id: "work-innoup-pr-by-dev", module: "Elixir.MidashWeb.Widgets.GithubPrsWidget"})}
          collapsible
        >
          <.live_component
            module={GithubPrsWidget}
            id="work-innoup-pr-by-dev"
            repo="innoshiftco/innoup"
            token={@github_token}
            base="staging"
          />
        </.widget>

        <.widget
          id="w-innosync-my-prs"
          title="innosync — my prs"
          on_refresh={JS.push("refresh", value: %{id: "work-innosync-my-prs", module: "Elixir.MidashWeb.Widgets.GithubMyPrsWidget"})}
          collapsible
        >
          <.live_component
            module={GithubMyPrsWidget}
            id="work-innosync-my-prs"
            repo="innoshiftco/innosync"
            token={@github_token}
            me={@github_username}
            base="staging"
          />
        </.widget>

        <.widget
          id="w-innoup-my-prs"
          title="innoup — my prs"
          on_refresh={JS.push("refresh", value: %{id: "work-innoup-my-prs", module: "Elixir.MidashWeb.Widgets.GithubMyPrsWidget"})}
          collapsible
        >
          <.live_component
            module={GithubMyPrsWidget}
            id="work-innoup-my-prs"
            repo="innoshiftco/innoup"
            token={@github_token}
            me={@github_username}
            base="staging"
          />
        </.widget>

      </.col>

      <%!-- Center column: ClickUp tasks + pending reviews --%>
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

        <.widget
          id="w-innosync-pending"
          title="innosync — pending review"
          on_refresh={JS.push("refresh", value: %{id: "work-innosync-pending-review", module: "Elixir.MidashWeb.Widgets.GithubPendingReviewWidget"})}
          collapsible
        >
          <.live_component
            module={GithubPendingReviewWidget}
            id="work-innosync-pending-review"
            repo="innoshiftco/innosync"
            token={@github_token}
            me={@github_username}
            base="staging"
          />
        </.widget>

        <.widget
          id="w-innoup-pending"
          title="innoup — pending review"
          on_refresh={JS.push("refresh", value: %{id: "work-innoup-pending-review", module: "Elixir.MidashWeb.Widgets.GithubPendingReviewWidget"})}
          collapsible
        >
          <.live_component
            module={GithubPendingReviewWidget}
            id="work-innoup-pending-review"
            repo="innoshiftco/innoup"
            token={@github_token}
            me={@github_username}
            base="staging"
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
