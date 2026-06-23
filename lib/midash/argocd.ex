defmodule Midash.ArgoCD do
  @moduledoc """
  ArgoCD API client.

  Config via env vars:
  - ARGOCD_URL  — base URL, e.g. https://argocd.example.com
  - ARGOCD_TOKEN — bearer token
  """

  def base_url, do: Midash.ConfigStore.get("ARGOCD_URL", "")
  def token, do: Midash.ConfigStore.get("ARGOCD_TOKEN", "")

  @doc """
  Fetches all applications. Returns `{:ok, [app]}` or `{:error, reason}`.

  Each app map includes: name, sync_status, health_status, namespace, project.
  """
  def fetch_applications(base_url, token) do
    with :ok <- validate_config(base_url, token) do
      base_url = normalize_base_url(base_url)

      url =
        "#{base_url}/api/v1/applications?fields=items.metadata.name,items.metadata.namespace,items.spec.project,items.status.sync.status,items.status.health.status"

      case get(url, token) do
        {:ok, %{"items" => items}} ->
          apps =
            Enum.map(items, fn item ->
              %{
                name: get_in(item, ["metadata", "name"]),
                namespace: get_in(item, ["metadata", "namespace"]) || "default",
                project: get_in(item, ["spec", "project"]) || "default",
                sync_status: get_in(item, ["status", "sync", "status"]) || "Unknown",
                health_status: get_in(item, ["status", "health", "status"]) || "Unknown"
              }
            end)

          {:ok, apps}

        {:ok, _} ->
          {:ok, []}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Fetches the resource tree for a single application, filtered to Deployment kind.
  Returns `{:ok, [resource]}` or `{:error, reason}`.

  Each resource map includes: name, kind, health_status, sync_status.
  """
  def fetch_app_resources(base_url, token, app_name) do
    with :ok <- validate_config(base_url, token) do
      base_url = normalize_base_url(base_url)
      url = "#{base_url}/api/v1/applications/#{app_name}/resource-tree"

      case get(url, token) do
        {:ok, %{"nodes" => nodes}} ->
          resources =
            nodes
            |> Enum.filter(&(&1["kind"] == "Deployment"))
            |> Enum.map(fn node ->
              %{
                name: node["name"],
                kind: node["kind"],
                namespace: node["namespace"],
                health_status: get_in(node, ["health", "status"]) || "Unknown"
              }
            end)
            |> Enum.sort_by(& &1.name)

          {:ok, resources}

        {:ok, _} ->
          {:ok, []}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp validate_config(base_url, token) do
    cond do
      blank?(base_url) -> {:error, "ARGOCD_URL not configured"}
      blank?(token) -> {:error, "ARGOCD_TOKEN not configured"}
      true -> :ok
    end
  end

  defp blank?(value), do: value |> to_string() |> String.trim() == ""

  defp normalize_base_url(base_url), do: base_url |> String.trim() |> String.trim_trailing("/")

  defp get(url, token) do
    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    opts = [ssl_options: [{:verify, :verify_none}]]

    try do
      case :hackney.get(url, headers, "", opts) do
        {:ok, 200, _headers, ref} ->
          {:ok, body} = :hackney.body(ref)

          case Jason.decode(body) do
            {:ok, data} -> {:ok, data}
            {:error, _} -> {:error, "failed to parse response"}
          end

        {:ok, status, _headers, ref} ->
          {:ok, body} = :hackney.body(ref)
          {:error, "HTTP #{status}: #{body}"}

        {:error, reason} ->
          {:error, inspect(reason)}
      end
    rescue
      e -> {:error, Exception.message(e)}
    catch
      _kind, reason -> {:error, inspect(reason)}
    end
  end
end
