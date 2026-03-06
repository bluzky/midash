defmodule Midash.Sentry do
  @moduledoc """
  Self-hosted Sentry API client for fetching issues.

  Uses Finch to make requests to https://sentry.innoshift.co/
  """

  require Logger

  @sentry_url "https://sentry.innoshift.co"
  @api_path "/api/0"

  @doc """
  Fetches issues from a Sentry project.

  Args:
  - `org_slug` - Organization slug (e.g., "gdec")
  - `project_slug` - Project slug (e.g., "oms")
  - `filters` - Map of Sentry query filters (optional)
    - `"environment"` - Environment filter (e.g., "gdec-prod")
    - `"query"` - Sentry query string (e.g., "lastSeen:>=2026-03-05")
  - `opts` - Keyword list of options
    - `:limit` - Number of issues to return (default: 10)
    - `:sort` - Sort order (default: "freq")

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

  ## Examples

      # Fetch issues from last 24 hours in a specific environment
      fetch_issues("gdec", "oms", %{"environment" => "gdec-prod", "query" => "lastSeen:>=2026-03-05"})

      # Fetch all issues with custom sort
      fetch_issues("gdec", "oms", %{}, sort: "date")
  """
  def fetch_issues(org_slug, project_slug, filters \\ %{}, opts \\ []) do
    token = System.get_env("SENTRY_TOKEN")
    limit = Keyword.get(opts, :limit, 10)
    sort = Keyword.get(opts, :sort, "freq")

    if is_nil(token) do
      Logger.error("[Sentry] SENTRY_TOKEN environment variable is not set!")
      {:error, "SENTRY_TOKEN not configured"}
    else
      do_fetch_issues(token, org_slug, project_slug, filters, limit, sort)
    end
  end

  defp do_fetch_issues(token, org_slug, project_slug, filters, limit, sort) do
    url = "#{@sentry_url}#{@api_path}/projects/#{org_slug}/#{project_slug}/issues/"

    # Build query parameters from filters
    query_parts = build_query_params(filters, limit, sort)

    # Use URI.encode_query to properly encode the query parameters
    query = "?" <> URI.encode_query(query_parts)
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
            {:ok, Enum.map(issues, &normalize_issue/1)}

          {:ok, _} ->
            {:error, "unexpected sentry response format"}

          {:error, reason} ->
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

  defp build_query_params(filters, limit, sort) do
    # Start with limit and sort (always included)
    query_parts = [
      {"limit", to_string(limit)},
      {"sort", sort}
    ]

    # Add query filter if present
    query_parts =
      case Map.get(filters, "query") do
        nil -> query_parts
        query_str -> [{"query", query_str} | query_parts]
      end

    # Add environment filter if present
    query_parts =
      case Map.get(filters, "environment") do
        nil -> query_parts
        env -> [{"environment", env} | query_parts]
      end

    query_parts
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
