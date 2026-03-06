defmodule MidashWeb.MonitorLive do
  use MidashWeb, :live_view

  alias MidashWeb.Widgets.SentryIssuesWidget

  @impl true
  def mount(_params, _session, socket) do
    projects = load_projects()

    {:ok, assign(socket, projects: projects),
     layout: {MidashWeb.Layouts, :dashboard}}
  end

  defp load_projects do
    # Read projects from environment variables
    # Format: SENTRY_PROJECTS="sentry/gdec-oms:gdec-prod:gdec-dev,sentry/gdec-sync:gdec-prod:gdec-dev"
    # Each project is formatted as "org/project-slug:env1:env2:..."
    projects_env = System.get_env("SENTRY_PROJECTS", "")

    projects_env
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
    |> Enum.map(fn project ->
      case String.split(project, ":") do
        [project_spec | environments] ->
          case String.split(project_spec, "/") do
            [org, name] ->
              %{org: org, name: name, environments: environments}

            _ ->
              nil
          end

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  @impl true
  def handle_info({:fetch_sentry_issues, id}, socket) do
    send_update(SentryIssuesWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout current={MidashWeb.Nav.current_from_module(__MODULE__)}>
      <%= for project <- @projects do %>
        <.col span={6}>
          <div class="space-y-4">
            <%= for env <- project.environments do %>
              <.widget
                id={"w-monitor-#{project.name}-#{env}"}
                title={"#{project.org}/#{project.name} · #{env}"}
                collapsible
              >
                <.live_component
                  module={SentryIssuesWidget}
                  id={"sentry-#{project.org}-#{project.name}-#{env}"}
                  org_slug={project.org}
                  project_slug={project.name}
                  environment={env}
                />
              </.widget>
            <% end %>
          </div>
        </.col>
      <% end %>
    </.dashboard_layout>
    """
  end
end
