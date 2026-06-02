defmodule MidashWeb.ArgoCDLive do
  use MidashWeb, :live_view

  alias MidashWeb.Widgets.ArgoCDAppWidget

  @impl true
  def mount(_params, _session, socket) do
    base_url = System.get_env("ARGOCD_URL", "")
    token = System.get_env("ARGOCD_TOKEN", "")

    {grouped, error} =
      if connected?(socket) do
        case Midash.ArgoCD.fetch_applications(base_url, token) do
          {:ok, apps} ->
            grouped = %{
              prod: apps |> Enum.filter(&env_match?(&1.name, "prod")) |> Enum.map(& &1.name),
              stg:  apps |> Enum.filter(&env_match?(&1.name, "stg"))  |> Enum.map(& &1.name),
              dev:  apps |> Enum.filter(&(not env_match?(&1.name, "prod") and not env_match?(&1.name, "stg"))) |> Enum.map(& &1.name)
            }
            {grouped, nil}
          {:error, reason} ->
            {%{prod: [], stg: [], dev: []}, reason}
        end
      else
        {%{prod: [], stg: [], dev: []}, nil}
      end

    {:ok,
     assign(socket,
       base_url: base_url,
       token: token,
       grouped: grouped,
       error: error,
       loading: not connected?(socket)
     ), layout: {MidashWeb.Layouts, :dashboard}}
  end

  @impl true
  def handle_event("refresh", %{"id" => id, "module" => module}, socket) do
    send_update(String.to_existing_atom(module), id: id, action: :fetch)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:argocd_tick, id}, socket) do
    send_update(ArgoCDAppWidget, id: id, action: :fetch)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.dashboard_layout current={MidashWeb.Nav.current_from_module(__MODULE__)}>
      <div :if={@loading} class="col-span-12 text-muted-foreground text-sm p-4">loading applications...</div>
      <div :if={@error} class="col-span-12 text-destructive text-sm p-4">{@error}</div>

      <.col :if={!@loading && !@error} span={4}>
        <div class="text-xs text-destructive uppercase tracking-widest mb-3 px-1">production</div>
        <div :if={@grouped.prod == []} class="text-muted-foreground text-sm px-1">no apps</div>
        <%= for app_name <- @grouped.prod do %>
          <.app_widget app_name={app_name} base_url={@base_url} token={@token} header_class="text-destructive" />
        <% end %>
      </.col>

      <.col :if={!@loading && !@error} span={4}>
        <div class="text-xs text-yellow-400 uppercase tracking-widest mb-3 px-1">staging</div>
        <div :if={@grouped.stg == []} class="text-muted-foreground text-sm px-1">no apps</div>
        <%= for app_name <- @grouped.stg do %>
          <.app_widget app_name={app_name} base_url={@base_url} token={@token} header_class="text-yellow-400" />
        <% end %>
      </.col>

      <.col :if={!@loading && !@error} span={4}>
        <div class="text-xs text-muted-foreground uppercase tracking-widest mb-3 px-1">dev / other</div>
        <div :if={@grouped.dev == []} class="text-muted-foreground text-sm px-1">no apps</div>
        <%= for app_name <- @grouped.dev do %>
          <.app_widget app_name={app_name} base_url={@base_url} token={@token} header_class="" />
        <% end %>
      </.col>
    </.dashboard_layout>
    """
  end

  defp app_widget(assigns) do
    ~H"""
    <.widget
      id={"w-argocd-#{@app_name}"}
      title={@app_name}
      header_class={@header_class}
      on_refresh={JS.push("refresh", value: %{id: "argocd-#{@app_name}", module: "Elixir.MidashWeb.Widgets.ArgoCDAppWidget"})}
      collapsible
    >
      <.live_component
        module={ArgoCDAppWidget}
        id={"argocd-#{@app_name}"}
        app_name={@app_name}
        base_url={@base_url}
        token={@token}
      />
    </.widget>
    """
  end

  defp env_match?(name, env) do
    name |> String.downcase() |> String.contains?(env)
  end
end
