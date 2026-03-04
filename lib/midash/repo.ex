defmodule Midash.Repo do
  use Ecto.Repo,
    otp_app: :midash,
    adapter: Ecto.Adapters.Postgres
end
