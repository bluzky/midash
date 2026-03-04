defmodule Midash.Clickup do
  @moduledoc """
  Shared helpers for ClickUp API and task data.
  """

  @statuses [
    %{key: "testing failed", label: "testing failed", color: "#f87171"},
    %{key: "in progress", label: "in progress", color: "#fbbf24"},
    %{key: "in review", label: "in review", color: "#a78bfa"},
    %{key: "dev ready", label: "dev ready", color: "#34d399"},
    %{key: "verified", label: "verified", color: "#22d3ee"}
  ]

  def statuses, do: @statuses

  def fetch_tasks(token, team_id, user_id) do
    url = "https://api.clickup.com/api/v2/team/#{team_id}/task?assignees[]=#{user_id}&include_closed=false"
    req = Finch.build(:get, url, [{"Authorization", token}])

    case Finch.request(req, Midash.Finch) do
      {:ok, %{status: 200, body: body}} ->
        case Jason.decode!(body) do
          %{"tasks" => tasks} -> {:ok, tasks}
          _ -> {:ok, []}
        end

      {:ok, %{status: status}} ->
        {:error, "clickup api error: #{status}"}

      {:error, reason} ->
        {:error, "request failed: #{inspect(reason)}"}
    end
  end

  def count_by_status(tasks, status_key) do
    Enum.count(tasks, &matches_status?(&1, status_key))
  end

  def filter_by_status(tasks, status_key) do
    Enum.filter(tasks, &matches_status?(&1, status_key))
  end

  def format_due(nil), do: ""

  def format_due(ms_string) do
    case Integer.parse(ms_string) do
      {ms, _} ->
        dt = DateTime.from_unix!(div(ms, 1000))
        diff = DateTime.diff(dt, DateTime.utc_now(), :hour)

        cond do
          diff < 0 -> "overdue"
          diff < 24 -> "today"
          diff < 48 -> "tomorrow"
          true -> "#{div(diff, 24)}d"
        end

      _ ->
        ""
    end
  end

  defp matches_status?(task, status_key) do
    String.downcase(task["status"]["status"] || "") =~ status_key
  end
end
