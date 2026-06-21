defmodule MidashWeb.API.SentryController do
  use MidashWeb, :controller

  alias Midash.Sentry

  def issues(conn, params) do
    org = Map.get(params, "org", "")
    project = Map.get(params, "project", "")
    environment = Map.get(params, "environment", "")
    sort = Map.get(params, "sort", "freq")

    filters = if environment != "", do: %{"environment" => environment}, else: %{}

    case Sentry.fetch_issues(org, project, filters, sort: sort) do
      {:ok, issues} ->
        json(conn, %{data: issues})

      {:error, reason} ->
        conn |> put_status(502) |> json(%{error: reason})
    end
  end
end
