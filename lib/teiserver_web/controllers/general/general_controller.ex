defmodule TeiserverWeb.General.GeneralController do
  use CentralWeb, :controller
  alias Teiserver.Client

  plug(:add_breadcrumb, name: 'Teiserver', url: '/teiserver')

  plug(AssignPlug,
    sidemenu_active: "teiserver"
  )

  plug(Teiserver.ServerUserPlug)

  @spec index(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def index(conn, _params) do
    client = Client.get_client_by_id(conn.user_id)

    conn
    |> assign(:client, client)
    |> render("index.html")
  end

  @spec gdpr(Plug.Conn.t(), Map.t()) :: Plug.Conn.t()
  def gdpr(conn, _params) do
    host = Application.get_env(:central, CentralWeb.Endpoint)[:url][:host]
    website_url = "https://#{host}"

    conn
    |> assign(:game_name, Application.get_env(:central, Teiserver)[:game_name])
    |> assign(:game_name_short, Application.get_env(:central, Teiserver)[:game_name_short])
    |> assign(:main_website, Application.get_env(:central, Teiserver)[:main_website])
    |> assign(:github_repo, Application.get_env(:central, Teiserver)[:github_repo])
    |> assign(:website_url, website_url)
    |> assign(:privacy_email, Application.get_env(:central, Teiserver)[:privacy_email])
    |> render("gdpr.html")
  end
end
