defmodule Midash.Sentry do
  @moduledoc """
  Self-hosted Sentry API client for fetching issues.

  Uses Finch to make requests to https://sentry.innoshift.co/
  """

  require Logger

  @sentry_url "https://sentry.innoshift.co"
  @api_path "/api/0"

  @doc """
  Fetches issues from a Sentry project created within the last 24 hours.

  Args:
  - `org_slug` - Organization slug (e.g., "gdec")
  - `project_slug` - Project slug (e.g., "oms")
  - `environment` - Optional environment filter (e.g., "gdec-prod", "gdec-dev"), defaults to nil

  Reads SENTRY_TOKEN from environment variables.

  Returns `{:ok, issues}` where each issue is a map with:
  - `"id"` - issue ID
  - `"title"` - issue title
  - `"url"` - link to issue in Sentry
  - `"count"` - number of events
  - `"level"` - severity level (error, warning, info, etc.)
  - `"firstSeen"` - when issue was first seen (ISO 8601)
  - `"lastSeen"` - when issue was last seen (ISO 8601)
  - `"shortID"` - short identifier like "OMS-1"
  - `"platform"` - platform (python, javascript, etc.)
  """
  def fetch_recent_issues(org_slug, project_slug, environment \\ nil, sort \\ "freq") do
    token = System.get_env("SENTRY_TOKEN")

    Logger.info("[Sentry] Fetching issues - Org: #{org_slug}, Project: #{project_slug}, Env: #{environment || "all"}, Sort: #{sort}")
    Logger.debug("[Sentry] Token (masked): #{mask_token(token)}")

    if is_nil(token) do
      Logger.error("[Sentry] SENTRY_TOKEN environment variable is not set!")
      {:error, "SENTRY_TOKEN not configured"}
    else
      do_fetch_issues(token, org_slug, project_slug, environment, sort)
    end
  end

  defp do_fetch_issues(token, org_slug, project_slug, environment, sort) do
    # Get issues from last 24 hours
    url = "#{@sentry_url}#{@api_path}/projects/#{org_slug}/#{project_slug}/issues/"

    # Build query with optional environment filter
    query_parts = ["age:-24h", "limit=10", "sort=#{sort}"]
    query_parts = if environment, do: ["environment:#{environment}" | query_parts], else: query_parts

    query = "?" <> Enum.join(query_parts, "&")
    full_url = url <> query

    headers = [
      {"authorization", "Bearer #{token}"},
      {"content-type", "application/json"}
    ]

    Logger.info("[Sentry] Fetching from: #{full_url}")

    request = Finch.build(:get, full_url, headers)

    case Finch.request(request, Midash.Finch) do
      {:ok, %Finch.Response{status: 200, body: resp_body}} ->
        Logger.info("[Sentry] Success: received 200 OK")

        case Jason.decode(resp_body) do
          {:ok, issues} when is_list(issues) ->
            Logger.info("[Sentry] Decoded #{length(issues)} issues")
            {:ok, Enum.map(issues, &normalize_issue/1)}

          {:ok, _} ->
            Logger.error("[Sentry] Response is not a list: #{inspect(resp_body)}")
            {:error, "unexpected sentry response format"}

          {:error, reason} ->
            Logger.error("[Sentry] JSON decode error: #{inspect(reason)}")
            {:error, "json decode error: #{inspect(reason)}"}
        end

      {:ok, %Finch.Response{status: 401, body: resp_body}} ->
        Logger.error("[Sentry] Unauthorized (401): #{resp_body}")
        {:error, "unauthorized: check your sentry token"}

      {:ok, %Finch.Response{status: 404, body: resp_body}} ->
        Logger.error("[Sentry] Not found (404): #{resp_body}")
        {:error, "project not found: check org/project slugs"}

      {:ok, %Finch.Response{status: status, body: resp_body}} ->
        Logger.error("[Sentry] Error #{status}: #{resp_body}")
        {:error, "sentry api error: #{status}"}

      {:error, reason} ->
        Logger.error("[Sentry] Request failed: #{inspect(reason)}")
        {:error, "request failed: #{inspect(reason)}"}
    end
  end

  defp mask_token(nil), do: "NOT SET"
  defp mask_token(token) do
    case String.length(token) do
      len when len > 10 -> String.slice(token, 0, 5) <> "..." <> String.slice(token, -4..-1)
      _ -> "***"
    end
  end

  defp normalize_issue(issue) do
    %{
      "id" => issue["id"],
      "title" => issue["title"],
      "url" => issue["permalink"],
      "count" => issue["count"],
      "level" => issue["level"],
      "firstSeen" => issue["firstSeen"],
      "lastSeen" => issue["lastSeen"],
      "shortID" => issue["shortID"],
      "platform" => issue["platform"]
    }
  end
end
