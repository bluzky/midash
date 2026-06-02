defmodule MidashWeb.Widgets.ArgoCDAppWidget do
  @moduledoc """
  Shows the Deployment resources for a single ArgoCD application.

  Required assigns:
  - `app_name`  — ArgoCD application name
  - `base_url`  — ArgoCD base URL
  - `token`     — ArgoCD bearer token
  """
  use MidashWeb, :live_component

  alias Midash.ArgoCD

  @refresh_interval 60_000

  @impl true
  def mount(socket) do
    {:ok, assign(socket, resources: [], sync_status: "Unknown", health_status: "Unknown", loading: true, error: nil)}
  end

  @impl true
  def update(%{action: :fetch}, socket) do
    {:ok, fetch_resources(socket)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if connected?(socket) do
      send(self(), {:argocd_tick, socket.assigns.id})
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@loading} class="text-muted-foreground text-sm py-2">fetching...</div>
      <div :if={@error} class="text-destructive text-sm py-2">{@error}</div>
      <div :if={!@loading && !@error}>
        <div class="flex items-center gap-2 mb-2 text-xs text-muted-foreground">
          <span>app: <span class={health_color(@health_status)}>{@health_status}</span></span>
          <span>·</span>
          <span>sync: <span class={sync_color(@sync_status)}>{@sync_status}</span></span>
        </div>
        <div :if={@resources == []} class="text-muted-foreground text-sm">no deployments found</div>
        <div :if={@resources != []} class="divide-y divide-border text-sm">
          <%= for resource <- @resources do %>
            <div class="flex items-center justify-between py-1 gap-2">
              <span class="text-foreground font-mono truncate">{resource.name}</span>
              <div class="flex items-center gap-2 shrink-0">
                <span class={["text-xs", health_color(resource.health_status)]}>
                  <span class="mr-1">●</span>{resource.health_status}
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp fetch_resources(socket) do
    Process.send_after(self(), {:argocd_tick, socket.assigns.id}, @refresh_interval)

    base_url = socket.assigns.base_url
    token = socket.assigns.token
    app_name = socket.assigns.app_name

    with {:ok, apps} <- ArgoCD.fetch_applications(base_url, token),
         app when not is_nil(app) <- Enum.find(apps, &(&1.name == app_name)),
         {:ok, resources} <- ArgoCD.fetch_app_resources(base_url, token, app_name) do
      assign(socket,
        resources: resources,
        sync_status: app.sync_status,
        health_status: app.health_status,
        loading: false,
        error: nil
      )
    else
      nil -> assign(socket, loading: false, error: "application not found")
      {:error, reason} -> assign(socket, loading: false, error: reason)
    end
    |> push_event("refresh_done", %{id: socket.assigns.id})
  end

  defp health_color("Healthy"), do: "text-green-400"
  defp health_color("Degraded"), do: "text-red-400"
  defp health_color("Progressing"), do: "text-yellow-400"
  defp health_color("Suspended"), do: "text-orange-400"
  defp health_color("Missing"), do: "text-red-600"
  defp health_color(_), do: "text-muted-foreground"

  defp sync_color("Synced"), do: "text-green-400"
  defp sync_color("OutOfSync"), do: "text-yellow-400"
  defp sync_color(_), do: "text-muted-foreground"
end
