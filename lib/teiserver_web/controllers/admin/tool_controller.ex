defmodule TeiserverWeb.Admin.ToolController do
  use CentralWeb, :controller
  alias Teiserver.Telemetry
  alias Central.Helpers.TimexHelper

  plug(AssignPlug,
    sidemenu_active: ["teiserver", "teiserver_admin"]
  )

  plug Bodyguard.Plug.Authorize,
    policy: Teiserver.Account.Admin,
    action: {Phoenix.Controller, :action_name},
    user: {Central.Account.AuthLib, :current_user}

  plug(:add_breadcrumb, name: 'Teiserver', url: '/teiserver')
  plug(:add_breadcrumb, name: 'Admin', url: '/teiserver/admin')

  @spec index(Plug.Conn.t(), map) :: Plug.Conn.t()
  def index(conn, _params) do
    render(conn, "index.html")
  end

  @spec convert_form(Plug.Conn.t(), map) :: Plug.Conn.t()
  def convert_form(conn, _params) do
    render(conn, "convert_form.html")
  end

  @spec convert_post(Plug.Conn.t(), map) :: Plug.Conn.t()
  def convert_post(conn, %{"file_upload" => file_upload}) do
    {:ok, _job} =
      case File.read(file_upload.path) do
        {:ok, body} ->
          %{body: body}
          |> Teiserver.UberserverConvert.new()
          |> Oban.insert()

        error ->
          throw(error)
      end

    render(conn, "convert_post.html")
  end

  @spec day_metrics_list(Plug.Conn.t(), map) :: Plug.Conn.t()
  def day_metrics_list(conn, _params) do
    logs =
      Telemetry.list_telemetry_day_logs(
        # search: [user_id: params["user_id"]],
        # joins: [:user],
        order: "Newest first",
        limit: 31
      )

    conn
    |> assign(:logs, logs)
    |> render("day_metrics_list.html")
  end

  @spec day_metrics_show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def day_metrics_show(conn, %{"date" => date_str}) do
    date = TimexHelper.parse_ymd(date_str)
    log = Telemetry.get_telemetry_day_log(date)

    users =
      [log]
      |> Telemetry.user_lookup()

    conn
    |> assign(:date, date)
    |> assign(:data, log.data)
    |> assign(:users, users)
    |> render("day_metrics_show.html")
  end

  @spec day_metrics_today(Plug.Conn.t(), map) :: Plug.Conn.t()
  def day_metrics_today(conn, _params) do
    data = Telemetry.get_todays_log()

    users =
      [%{data: data}]
      |> Telemetry.user_lookup()

    conn
    |> assign(:date, Timex.today())
    |> assign(:data, data)
    |> assign(:users, users)
    |> render("day_metrics_show.html")
  end

  @spec day_metrics_export(Plug.Conn.t(), map) :: Plug.Conn.t()
  def day_metrics_export(conn, _params = %{"date" => _date}) do
    # anonymous = params["anonymous"]

    # log = date
    #   |> TimexHelper.parse_ymd
    #   |> Telemetry.get_telemetry_day_log

    conn
  end
end
