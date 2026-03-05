defmodule Midash.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    db_path = Application.app_dir(:midash, "priv/cubdb")
    File.mkdir_p!(db_path)

    children = [
      MidashWeb.Telemetry,
      Midash.Repo,
      {CubDB, data_dir: db_path, name: Midash.Store.DB},
      {DNSCluster, query: Application.get_env(:midash, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Midash.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Midash.Finch},
      # Start a worker by calling: Midash.Worker.start_link(arg)
      # {Midash.Worker, arg},
      # Start to serve requests, typically the last entry
      MidashWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Midash.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MidashWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
