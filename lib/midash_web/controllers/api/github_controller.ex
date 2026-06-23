defmodule MidashWeb.API.GithubController do
  use MidashWeb, :controller

  alias Midash.GitHub

  def prs(conn, params) do
    repos = Map.get(params, "repos", [])
    token = Midash.ConfigStore.get("GITHUB_TOKEN", "")

    with :ok <- require_config("GITHUB_TOKEN", token) do
      results =
        repos
        |> Enum.map(fn repo ->
          [owner, name] = String.split(repo, "/", parts: 2)

          case GitHub.fetch_open_prs(token, owner, name) do
            {:ok, prs} ->
              filtered = Enum.reject(prs, &(&1["base_ref"] == "develop"))
              {repo, %{prs: filtered, error: nil}}

            {:error, reason} ->
              {repo, %{prs: [], error: reason}}
          end
        end)
        |> Map.new()

      json(conn, %{data: results})
    else
      {:error, reason} -> conn |> put_status(502) |> json(%{error: reason})
    end
  end

  def my_prs(conn, params) do
    repos = Map.get(params, "repos", [])
    token = Midash.ConfigStore.get("GITHUB_TOKEN", "")
    me = Map.get(params, "me", Midash.ConfigStore.get("GITHUB_USERNAME", ""))

    with :ok <- require_config("GITHUB_TOKEN", token),
         :ok <- require_config("GITHUB_USERNAME", me) do
      results =
        repos
        |> Enum.map(fn repo ->
          [owner, name] = String.split(repo, "/", parts: 2)

          case GitHub.fetch_open_prs(token, owner, name) do
            {:ok, prs} ->
              my =
                prs
                |> Enum.filter(&(&1["author"] == me && &1["base_ref"] != "develop"))
                |> Enum.map(fn pr ->
                  approvals = Enum.count(pr["reviews"], &(&1["state"] == "APPROVED"))
                  Map.put(pr, "approvals", approvals)
                end)

              {repo, %{prs: my, error: nil}}

            {:error, reason} ->
              {repo, %{prs: [], error: reason}}
          end
        end)
        |> Map.new()

      json(conn, %{data: results, me: me})
    else
      {:error, reason} -> conn |> put_status(502) |> json(%{error: reason})
    end
  end

  def pending_review(conn, params) do
    repos = Map.get(params, "repos", [])
    token = Midash.ConfigStore.get("GITHUB_TOKEN", "")
    me = Map.get(params, "me", Midash.ConfigStore.get("GITHUB_USERNAME", ""))

    with :ok <- require_config("GITHUB_TOKEN", token),
         :ok <- require_config("GITHUB_USERNAME", me) do
      results =
        repos
        |> Enum.map(fn repo ->
          [owner, name] = String.split(repo, "/", parts: 2)

          case GitHub.fetch_open_prs(token, owner, name) do
            {:ok, prs} ->
              pending =
                prs
                |> Enum.filter(fn pr ->
                  pr["author"] != me &&
                    pr["base_ref"] != "develop" &&
                    not Enum.any?(
                      pr["reviews"],
                      &(&1["author"] == me && &1["state"] == "APPROVED")
                    )
                end)

              {repo, %{prs: pending, error: nil}}

            {:error, reason} ->
              {repo, %{prs: [], error: reason}}
          end
        end)
        |> Map.new()

      json(conn, %{data: results, me: me})
    else
      {:error, reason} -> conn |> put_status(502) |> json(%{error: reason})
    end
  end

  defp require_config(key, value) do
    if value |> to_string() |> String.trim() == "" do
      {:error, "#{key} not configured"}
    else
      :ok
    end
  end
end
