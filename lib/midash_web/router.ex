defmodule MidashWeb.Router do
  use MidashWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MidashWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
  end

  pipeline :bin_receiver do
    plug :accepts, ["json", "html", "text", "*/*"]
  end

  scope "/api", MidashWeb.API do
    pipe_through :api

    get "/config", ConfigController, :index
    post "/config", ConfigController, :update

    get "/crypto/funding", CryptoController, :funding
    get "/crypto/klines", CryptoController, :klines

    get "/github/prs", GithubController, :prs
    get "/github/my-prs", GithubController, :my_prs
    get "/github/pending-review", GithubController, :pending_review

    get "/clickup/tasks", ClickupController, :tasks

    get "/sentry/issues", SentryController, :issues

    get "/argocd/apps", ArgoCDController, :apps

    post "/toolkit/execute", ToolkitController, :execute
    post "/toolkit/barcode", ToolkitController, :barcode
    post "/toolkit/mau", ToolkitController, :mau
    post "/toolkit/map-to-json", ToolkitController, :map_to_json
    post "/toolkit/json-to-map", ToolkitController, :json_to_map

    get "/postbin/bins", PostbinController, :index
    post "/postbin/bins", PostbinController, :create
    get "/postbin/bins/:id/requests", PostbinController, :requests
    delete "/postbin/bins/:id", PostbinController, :delete
  end

  scope "/bin/:bin_id", MidashWeb do
    pipe_through :bin_receiver

    match :*, "/", RequestBinPlug, []
    match :*, "/*path", RequestBinPlug, []
  end

  # Dev routes must come before the SPA catch-all
  if Application.compile_env(:midash, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MidashWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # SPA catch-all — must be last
  scope "/", MidashWeb do
    pipe_through :browser

    get "/*path", PageController, :index
  end
end
