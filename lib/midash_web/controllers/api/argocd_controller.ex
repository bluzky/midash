defmodule MidashWeb.API.ArgoCDController do
  use MidashWeb, :controller

  alias Midash.ArgoCD

  def apps(conn, _params) do
    base_url = ArgoCD.base_url()
    token = ArgoCD.token()

    case ArgoCD.fetch_applications(base_url, token) do
      {:ok, apps} ->
        apps_with_resources =
          Enum.map(apps, fn app ->
            case ArgoCD.fetch_app_resources(base_url, token, app.name) do
              {:ok, resources} -> Map.put(app, :resources, resources)
              {:error, _} -> Map.put(app, :resources, [])
            end
          end)

        json(conn, %{data: apps_with_resources})

      {:error, reason} ->
        conn |> put_status(502) |> json(%{error: reason})
    end
  end
end
