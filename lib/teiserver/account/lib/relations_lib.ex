defmodule Teiserver.Account.RelationsLib do
  alias Central.Communication
  alias Central.Helpers.StylingHelper
  alias Phoenix.PubSub
  alias Teiserver.User
  alias Teiserver.Account.UserCache
  alias Teiserver.Data.Types, as: T

  @spec accept_friend_request(T.userid() | nil, T.userid() | nil) :: User.t() | nil
  def accept_friend_request(nil, _), do: nil
  def accept_friend_request(_, nil), do: nil
  def accept_friend_request(requester_id, accepter_id) do
    accepter = UserCache.get_user_by_id(accepter_id)

    if requester_id in accepter.friend_requests do
      requester = UserCache.get_user_by_id(requester_id)

      # Add to friends, remove from requests
      new_accepter =
        Map.merge(accepter, %{
          friends: [requester_id | accepter.friends],
          friend_requests: Enum.filter(accepter.friend_requests, fn f -> f != requester_id end)
        })

      new_requester =
        Map.merge(requester, %{
          friends: [accepter_id | requester.friends]
        })

      UserCache.update_user(new_accepter, persist: true)
      UserCache.update_user(new_requester, persist: true)

      Communication.notify(
        new_requester.id,
        %{
          title: "#{new_accepter.name} accepted your friend request",
          body: "#{new_accepter.name} accepted your friend request",
          icon: Teiserver.icon(:friend),
          colour: StylingHelper.get_fg(:success),
          redirect: "/teiserver/account/relationships#friends"
        },
        1,
        prevent_duplicates: true
      )

      # Now push out the updates
      PubSub.broadcast(
        Central.PubSub,
        "legacy_user_updates:#{requester_id}",
        {:this_user_updated, [:friends]}
      )

      PubSub.broadcast(
        Central.PubSub,
        "legacy_user_updates:#{accepter_id}",
        {:this_user_updated, [:friends, :friend_requests]}
      )

      new_accepter
    else
      accepter
    end
  end

  @spec decline_friend_request(T.userid() | nil, T.userid() | nil) :: User.t() | nil
  def decline_friend_request(nil, _), do: nil
  def decline_friend_request(_, nil), do: nil
  def decline_friend_request(requester_id, decliner_id) do
    decliner = UserCache.get_user_by_id(decliner_id)

    if requester_id in decliner.friend_requests do
      # Remove from requests
      new_decliner =
        Map.merge(decliner, %{
          friend_requests: Enum.filter(decliner.friend_requests, fn f -> f != requester_id end)
        })

      UserCache.update_user(new_decliner, persist: true)

      # Now push out the updates
      PubSub.broadcast(
        Central.PubSub,
        "legacy_user_updates:#{decliner_id}",
        {:this_user_updated, [:friend_requests]}
      )

      new_decliner
    else
      decliner
    end
  end

  @spec create_friend_request(T.userid() | nil, T.userid() | nil) :: User.t() | nil
  def create_friend_request(nil, _), do: nil
  def create_friend_request(_, nil), do: nil
  def create_friend_request(requester_id, potential_id) do
    potential = UserCache.get_user_by_id(potential_id)

    if requester_id not in potential.friend_requests and requester_id not in potential.friends do
      # Add to requests
      new_potential =
        Map.merge(potential, %{
          friend_requests: [requester_id | potential.friend_requests]
        })

      requester = UserCache.get_user_by_id(requester_id)
      UserCache.update_user(new_potential, persist: true)

      Communication.notify(
        new_potential.id,
        %{
          title: "New friend request from #{requester.name}",
          body: "New friend request from #{requester.name}",
          icon: Teiserver.icon(:friend),
          colour: StylingHelper.get_fg(:info),
          redirect: "/teiserver/account/relationships#requests"
        },
        1,
        prevent_duplicates: true
      )

      # Now push out the updates
      PubSub.broadcast(
        Central.PubSub,
        "legacy_user_updates:#{potential_id}",
        {:this_user_updated, [:friend_requests]}
      )

      new_potential
    else
      potential
    end
  end

  @spec ignore_user(T.userid() | nil, T.userid() | nil) :: User.t() | nil
  def ignore_user(nil, _), do: nil
  def ignore_user(_, nil), do: nil
  def ignore_user(ignorer_id, ignored_id) do
    ignorer = UserCache.get_user_by_id(ignorer_id)

    if ignored_id not in ignorer.ignored do
      # Add to requests
      new_ignorer =
        Map.merge(ignorer, %{
          ignored: [ignored_id | ignorer.ignored]
        })

      UserCache.update_user(new_ignorer, persist: true)

      # Now push out the updates
      PubSub.broadcast(
        Central.PubSub,
        "legacy_user_updates:#{ignorer_id}",
        {:this_user_updated, [:ignored]}
      )

      new_ignorer
    else
      ignorer
    end
  end

  @spec unignore_user(T.userid() | nil, T.userid() | nil) :: User.t() | nil
  def unignore_user(nil, _), do: nil
  def unignore_user(_, nil), do: nil
  def unignore_user(unignorer_id, unignored_id) do
    unignorer = UserCache.get_user_by_id(unignorer_id)

    if unignored_id in unignorer.ignored do
      # Add to requests
      new_unignorer =
        Map.merge(unignorer, %{
          ignored: Enum.filter(unignorer.ignored, fn f -> f != unignored_id end)
        })

      UserCache.update_user(new_unignorer, persist: true)

      # Now push out the updates
      PubSub.broadcast(
        Central.PubSub,
        "legacy_user_updates:#{unignorer_id}",
        {:this_user_updated, [:ignored]}
      )

      new_unignorer
    else
      unignorer
    end
  end

  @spec remove_friend(T.userid() | nil, T.userid() | nil) :: User.t() | nil
  def remove_friend(nil, _), do: nil
  def remove_friend(_, nil), do: nil
  def remove_friend(remover_id, removed_id) do
    remover = UserCache.get_user_by_id(remover_id)

    if removed_id in remover.friends do
      # Add to requests
      new_remover =
        Map.merge(remover, %{
          friends: Enum.filter(remover.friends, fn f -> f != removed_id end)
        })

      removed = UserCache.get_user_by_id(removed_id)

      new_removed =
        Map.merge(removed, %{
          friends: Enum.filter(removed.friends, fn f -> f != remover_id end)
        })

      UserCache.update_user(new_remover, persist: true)
      UserCache.update_user(new_removed, persist: true)

      # Now push out the updates
      PubSub.broadcast(
        Central.PubSub,
        "legacy_user_updates:#{remover_id}",
        {:this_user_updated, [:friends]}
      )

      PubSub.broadcast(
        Central.PubSub,
        "legacy_user_updates:#{removed_id}",
        {:this_user_updated, [:friends]}
      )

      new_remover
    else
      remover
    end
  end

  @spec list_combined_friendslist([T.userid()]) :: [User.t()]
  def list_combined_friendslist(userids) do
    friends = UserCache.list_users(userids)
      |> Enum.map(fn user -> Map.get(user, :friends) end)
      |> List.flatten

    # Combine friends and users, people are after all their own friends!
    Enum.uniq(userids ++ friends)
  end
end
