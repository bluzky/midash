defmodule MidashWeb.API.ClickupController do
  use MidashWeb, :controller

  alias Midash.Clickup

  def tasks(conn, _params) do
    token = System.get_env("CLICKUP_TOKEN", "")
    team_id = System.get_env("CLICKUP_TEAM_ID", "")
    user_id = System.get_env("CLICKUP_USER_ID", "")

    case Clickup.fetch_tasks(token, team_id, user_id) do
      {:ok, tasks} ->
        json(conn, %{data: tasks, statuses: Clickup.statuses(), team_id: team_id, user_id: user_id})

      {:error, reason} ->
        conn |> put_status(502) |> json(%{error: reason})
    end
  end
end
