defmodule MidashWeb.API.ConfigController do
  use MidashWeb, :controller

  def index(conn, _params) do
    sentry_projects = parse_sentry_projects(System.get_env("SENTRY_PROJECTS", ""))
    json(conn, %{sentry_projects: sentry_projects})
  end

  # Parses "org/project:env1:env2,..." into [{org, project, env}] entries
  defp parse_sentry_projects(""), do: []

  defp parse_sentry_projects(raw) do
    raw
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.flat_map(&parse_project_entry/1)
  end

  defp parse_project_entry(entry) do
    case String.split(entry, ":") do
      [_project_spec] ->
        []

      [project_spec | envs] ->
        case String.split(project_spec, "/") do
          [org, project] when org != "" and project != "" ->
            Enum.map(envs, fn env -> %{org: org, project: project, env: env} end)

          _ ->
            []
        end
    end
  end
end
