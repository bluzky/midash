defmodule MidashWeb.API.ConfigController do
  use MidashWeb, :controller

  @config_keys ~w(
    GITHUB_TOKEN
    GITHUB_USERNAME
    CLICKUP_TOKEN
    CLICKUP_TEAM_ID
    CLICKUP_USER_ID
    SENTRY_TOKEN
    SENTRY_PROJECTS
    ARGOCD_URL
    ARGOCD_TOKEN
  )

  def index(conn, _params) do
    sentry_projects = parse_sentry_projects(Midash.ConfigStore.get("SENTRY_PROJECTS", ""))
    json(conn, %{sentry_projects: sentry_projects, configured: configured()})
  end

  def update(conn, params) do
    values = Map.take(params, @config_keys)

    case Midash.ConfigStore.put_many(values) do
      {:ok, data} -> json(conn, %{ok: true, configured: configured_from(data)})
      {:error, reason} -> conn |> put_status(500) |> json(%{error: inspect(reason)})
    end
  end

  defp configured do
    Map.new(@config_keys, &{&1, Midash.ConfigStore.configured?(&1)})
  end

  defp configured_from(data) do
    Map.new(@config_keys, fn key ->
      stored = Map.get(data, key, "")
      value = if is_binary(stored) and stored != "", do: stored, else: System.get_env(key, "")
      {key, value != ""}
    end)
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
