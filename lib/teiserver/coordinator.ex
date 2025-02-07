defmodule Teiserver.Coordinator do
  alias Teiserver.Battle.Lobby
  alias Teiserver.User
  # alias Teiserver.Client
  alias Teiserver.Data.Types, as: T
  alias Teiserver.Coordinator.Parser
  require Logger

  @spec do_start() :: :ok
  defp do_start() do
    # Start the supervisor server
    {:ok, coordinator_pid} =
      DynamicSupervisor.start_child(Teiserver.Coordinator.DynamicSupervisor, {
        Teiserver.Coordinator.CoordinatorServer,
        name: Teiserver.Coordinator.CoordinatorServer,
        data: %{}
      })

    ConCache.put(:teiserver_consul_pids, :coordinator, coordinator_pid)
    send(coordinator_pid, :begin)
    :ok
  end

  # @spec get_coordinator_pid() :: pid()
  # defp get_coordinator_pid() do
  #   ConCache.get(:teiserver_coordinator, :coordinator)
  # end

  @spec start_coordinator() :: :ok | {:failure, String.t()}
  def start_coordinator() do
    cond do
      get_coordinator_userid() != nil ->
        {:failure, "Already started"}

      true ->
        do_start()
    end
  end

  @spec get_coordinator_userid() :: T.userid()
  def get_coordinator_userid() do
    ConCache.get(:application_metadata_cache, "teiserver_coordinator_userid")
  end

  @spec get_consul_pid(T.battle_id()) :: pid() | nil
  def get_consul_pid(battle_id) do
    ConCache.get(:teiserver_consul_pids, battle_id)
  end

  @spec start_consul(T.battle_id()) :: pid()
  def start_consul(battle_id) do
    {:ok, consul_pid} =
      DynamicSupervisor.start_child(Teiserver.Coordinator.DynamicSupervisor, {
        Teiserver.Coordinator.ConsulServer,
        name: "consul_#{battle_id}",
        data: %{
          battle_id: battle_id,
        }
      })

    send(consul_pid, :startup)
    consul_pid
  end

  @spec cast_consul(T.battle_id(), any) :: any
  def cast_consul(battle_id, msg) when is_integer(battle_id) do
    case get_consul_pid(battle_id) do
      nil -> nil
      pid -> send(pid, msg)
    end
  end

  @spec call_consul(pid() | T.battle_id(), any) :: any
  def call_consul(battle_id, msg) when is_integer(battle_id) do
    case get_consul_pid(battle_id) do
      nil -> nil
      pid -> GenServer.call(pid, msg)
    end
  end

  def allow_battlestatus_update?(client, battle_id) do
    call_consul(battle_id, {:request_user_change_status, client})
  end

  def handle_in(userid, msg, battle_id) do
    Parser.handle_in(userid, msg, battle_id)
  end

  def close_battle(battle_id) do
    case get_consul_pid(battle_id) do
      nil -> nil
      pid ->
        ConCache.delete(:teiserver_consul_pids, battle_id)
        DynamicSupervisor.terminate_child(Teiserver.Coordinator.DynamicSupervisor, pid)
    end
  end

  def send_to_host(from_id, battle_id, msg) do
    battle = Lobby.get_battle!(battle_id)
    # pid = Client.get_client_by_id(battle.founder_id).pid
    User.send_direct_message(from_id, battle.founder_id, msg)
    # send(pid, {:battle_updated, battle_id, {from_id, msg, battle_id}, :say})
    Logger.info("send_to_host - #{battle.id}, #{msg}")
  end

  def send_to_user(userid, msg) do
    User.send_direct_message(get_coordinator_userid(), userid, msg)
  end
end
