defmodule MidashWeb.Nav do
  @moduledoc """
  Shared navigation configuration for dashboard pages.
  """

  @nav_pages [
    %{id: :home, label: "home", path: "/"},
    %{id: :work, label: "work", path: "/work"},
    %{id: :monitor, label: "monitor", path: "/monitor"},
    %{id: :toolkit, label: "toolkit", path: "/toolkit"}
  ]

  def pages, do: @nav_pages

  @doc """
  Get the current page ID from a LiveView module name.

  Examples:
      iex> MidashWeb.Nav.current_from_module(MidashWeb.HomeLive)
      :home

      iex> MidashWeb.Nav.current_from_module(MidashWeb.WorkLive)
      :work
  """
  def current_from_module(module) do
    case module do
      MidashWeb.HomeLive -> :home
      MidashWeb.WorkLive -> :work
      MidashWeb.MonitorLive -> :monitor
      MidashWeb.ToolkitLive -> :toolkit
      _ -> nil
    end
  end
end
