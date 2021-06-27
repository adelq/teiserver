defmodule Teiserver.SpringTelemetryTest do
  use Central.ServerCase, async: false
  import Teiserver.TeiserverTestLib,
    only: [auth_setup: 0, _send_raw: 2, _recv_raw: 1, raw_setup: 0]

  setup do
    %{socket: socket, user: user} = auth_setup()
    {:ok, socket: socket, user: user}
  end

  test "test log_client_event call", %{socket: socket} do
    # Bad/malformed data
    _send_raw(socket, "c.telemetry.log_client_event event_name W10=-- rXTrJC0nAdWUmCH8Q7+kWQ==--\n")
    reply = _recv_raw(socket)
    assert reply == :timeout

    # Good data
    _send_raw(socket, "c.telemetry.log_client_event event_name W10= TXlWYWx1ZUdvZXNoZXJl\n")
    reply = _recv_raw(socket)
    assert reply == :timeout

    # Unauth
    %{socket: socket_raw} = raw_setup()
    _recv_raw(socket_raw)
    _send_raw(socket_raw, "c.telemetry.log_client_event event_name W10= TXlWYWx1ZUdvZXNoZXJl\n")
    reply = _recv_raw(socket_raw)
    assert reply == :timeout
  end

  test "test update_client_property call", %{socket: socket} do
    # Bad/malformed data
    _send_raw(socket, "c.telemetry.update_client_property property_name W10=-- rXTrJC0nAdWUmCH8Q7+kWQ==--\n")
    reply = _recv_raw(socket)
    assert reply == :timeout

    # Good data
    _send_raw(socket, "c.telemetry.update_client_property property_name W10= TXlWYWx1ZUdvZXNoZXJl\n")
    reply = _recv_raw(socket)
    assert reply == :timeout

    # Unauth
    %{socket: socket_raw} = raw_setup()
    _recv_raw(socket_raw)
    _send_raw(socket_raw, "c.telemetry.update_client_property property_name W10= TXlWYWx1ZUdvZXNoZXJl\n")
    reply = _recv_raw(socket_raw)
    assert reply == :timeout
  end

  test "test log_battle_event call", %{socket: socket} do
    # Bad/malformed data
    _send_raw(socket, "c.telemetry.log_battle_event battle_event_name W10=-- rXTrJC0nAdWUmCH8Q7+kWQ==--\n")
    reply = _recv_raw(socket)
    assert reply == :timeout

    # Good data
    _send_raw(socket, "c.telemetry.log_battle_event battle_event_name W10= TXlWYWx1ZUdvZXNoZXJl\n")
    reply = _recv_raw(socket)
    assert reply == :timeout

    # Unauth
    %{socket: socket_raw} = raw_setup()
    _recv_raw(socket_raw)
    _send_raw(socket_raw, "c.telemetry.log_battle_event battle_event_name W10= TXlWYWx1ZUdvZXNoZXJl\n")
    reply = _recv_raw(socket_raw)
    assert reply == :timeout
  end
end