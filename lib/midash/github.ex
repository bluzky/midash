defmodule Midash.GitHub do
  @moduledoc """
  Centralized GitHub GraphQL client.

  Uses Finch (already supervised as `Midash.Finch`) to make a single
  GraphQL request per repo, fetching open PRs with their reviews.
  """

  @graphql_url "https://api.github.com/graphql"

  @query """
  query($owner: String!, $repo: String!, $base: String!) {
    repository(owner: $owner, name: $repo) {
      pullRequests(states: OPEN, baseRefName: $base, first: 100, orderBy: {field: CREATED_AT, direction: DESC}) {
        nodes {
          number
          title
          url
          createdAt
          author { login }
          reviews(first: 50) {
            nodes {
              state
              author { login }
            }
          }
        }
      }
    }
  }
  """

  @doc """
  Fetches open PRs targeting `base` for `owner/repo` via a single GraphQL call.

  Returns `{:ok, prs}` where each PR is a map with:
  - `"number"`, `"title"`, `"url"`, `"created_at"` (ISO 8601)
  - `"author"` — GitHub login string
  - `"reviews"` — list of `%{"state" => "APPROVED"|..., "author" => login}`
  """
  def fetch_open_prs(token, owner, repo, base) do
    body =
      Jason.encode!(%{
        query: @query,
        variables: %{owner: owner, repo: repo, base: base}
      })

    headers = [
      {"authorization", "bearer #{token}"},
      {"content-type", "application/json"}
    ]

    request = Finch.build(:post, @graphql_url, headers, body)

    case Finch.request(request, Midash.Finch) do
      {:ok, %Finch.Response{status: 200, body: resp_body}} ->
        case Jason.decode!(resp_body) do
          %{"data" => %{"repository" => %{"pullRequests" => %{"nodes" => nodes}}}} ->
            {:ok, Enum.map(nodes, &normalize_pr/1)}

          %{"errors" => [%{"message" => msg} | _]} ->
            {:error, msg}

          _ ->
            {:error, "unexpected graphql response"}
        end

      {:ok, %Finch.Response{status: status}} ->
        {:error, "github api error: #{status}"}

      {:error, reason} ->
        {:error, "request failed: #{inspect(reason)}"}
    end
  end

  defp normalize_pr(node) do
    %{
      "number" => node["number"],
      "title" => node["title"],
      "url" => node["url"],
      "html_url" => node["url"],
      "created_at" => node["createdAt"],
      "author" => get_in(node, ["author", "login"]) || "ghost",
      "reviews" =>
        (get_in(node, ["reviews", "nodes"]) || [])
        |> Enum.map(fn r ->
          %{
            "state" => r["state"],
            "author" => get_in(r, ["author", "login"]) || "ghost"
          }
        end)
    }
  end
end
