defmodule TeiserverWeb.Battle.LobbyLive.Index do
  use TeiserverWeb, :live_view
  alias Phoenix.PubSub

  alias Teiserver
  alias Teiserver.Battle.Lobby
  alias Teiserver.Battle.LobbyLib

  @extra_menu_content """
  &nbsp;&nbsp;&nbsp;
    <a href='/teiserver/admin/client' class="btn btn-outline-primary">
      <i class="fas fa-fw fa-plug"></i>
      Clients
    </a>
  """

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> AuthPlug.live_call(session)
      |> NotificationPlug.live_call()

    extra_content = if allow?(socket, "teiserver.moderator.account") do
      @extra_menu_content
    end

    socket = socket
      |> add_breadcrumb(name: "Teiserver", url: "/teiserver")
      |> add_breadcrumb(name: "Battles", url: "/teiserver/battle/lobbies")
      |> assign(:sidemenu_active, "teiserver")
      |> assign(:colours, LobbyLib.colours())
      |> assign(:battles, Lobby.list_battles())
      |> assign(:menu_override, Routes.ts_general_general_path(socket, :index))
      |> assign(:extra_menu_content, extra_content)

    {:ok, socket, layout: {CentralWeb.LayoutView, "blank_live.html"}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:global_battle_updated, battle_id, :battle_opened}, socket) do
    new_battle = Lobby.get_battle(battle_id)
    battles = [new_battle | socket.assigns[:battles]]

    {:noreply, assign(socket, :battles, battles)}
  end

  def handle_info({:global_battle_updated, battle_id, :battle_closed}, socket) do
    battles =
      socket.assigns[:battles]
      |> Enum.filter(fn b -> b.id != battle_id end)

    {:noreply, assign(socket, :battles, battles)}
  end

  def handle_info({:global_battle_updated, battle_id, _reason}, socket) do
    battles =
      socket.assigns[:battles]
      |> Enum.map(fn battle ->
        if battle.id == battle_id do
          Lobby.get_battle(battle_id)
        else
          battle
        end
      end)

    {:noreply, assign(socket, :battles, battles)}
  end

  def handle_info({:add_user_to_battle, user_id, battle_id, _script_password}, socket) do
    battles =
      socket.assigns[:battles]
      |> Enum.map(fn battle ->
        if battle.id == battle_id do
          %{battle | player_count: battle.player_count + 1, players: [user_id | battle.players]}
        else
          battle
        end
      end)

    {:noreply, assign(socket, :battles, battles)}
  end

  def handle_info({:remove_user_from_battle, user_id, battle_id}, socket) do
    battles =
      socket.assigns[:battles]
      |> Enum.map(fn battle ->
        if battle.id == battle_id do
          new_players = Enum.filter(battle.players, fn p -> p != user_id end)
          %{battle | player_count: battle.player_count - 1, players: new_players}
        else
          battle
        end
      end)

    {:noreply, assign(socket, :battles, battles)}
  end

  def handle_info({:kick_user_from_battle, user_id, battle_id}, socket) do
    battles =
      socket.assigns[:battles]
      |> Enum.map(fn battle ->
        if battle.id == battle_id do
          new_players = Enum.filter(battle.players, fn p -> p != user_id end)
          %{battle | player_count: battle.player_count - 1, players: new_players}
        else
          battle
        end
      end)

    {:noreply, assign(socket, :battles, battles)}
  end

  defp apply_action(socket, :index, _params) do
    :ok = PubSub.subscribe(Central.PubSub, "legacy_all_battle_updates")

    socket
    |> assign(:page_title, "Listing Battles")
    |> assign(:battle, nil)
  end
end
