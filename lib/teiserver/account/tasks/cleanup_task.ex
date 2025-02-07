defmodule Teiserver.Account.Tasks.CleanupTask do
  use Oban.Worker, queue: :cleanup

  alias Teiserver.{User, Account}
  alias Teiserver.Account.UserCache

  @impl Oban.Worker
  @spec perform(any) :: :ok
  def perform(_) do
    # Find all users who are muted or banned
    # we have these anti-nil things to handle if the job
    # runs just after startup the users may not be in the cache
    Account.list_users(
      search: [
        mute_or_ban: true
      ],
      select: [:id]
    )
    |> Enum.each(fn %{id: userid} ->
      user = UserCache.get_user_by_id(userid)

      if user do
        user
        |> check_muted()
        |> check_banned()
        |> UserCache.update_user(persist: true)
      end
    end)

    :ok
  end

  defp check_muted(user) do
    if User.is_muted?(user) do
      user
    else
      %{user | muted: [false, nil]}
    end
  end

  defp check_banned(user) do
    if User.is_banned?(user) do
      user
    else
      %{user | banned: [false, nil]}
    end
  end
end
