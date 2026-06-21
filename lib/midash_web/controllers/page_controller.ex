defmodule MidashWeb.PageController do
  use MidashWeb, :controller

  def index(conn, _params) do
    conn
    |> put_root_layout(false)
    |> render(:index)
  end
end
