defmodule HttpClients.Creditas.TokenServerTest do
  use ExUnit.Case
  import Mock
  import Tesla.Mock

  alias HttpClients.Creditas.{Token, TokenServer}

  @creditas_url "https://test.com/api/internal_clients/tokens"

  @config [
    url: @creditas_url,
    credentials: %{
      username: "bcredi-chp",
      password: "password123",
      grant_type: "password"
    }
  ]

  @token_response %{
    "access_token" =>
      "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiY2IzZTQ4NzAtMDIyMC00YTMwLTkxYjctYThmY2RhMzRkYjNkIiwidXNlcl90eXBlIjoiYXBpLWNsaWVudCIsInRva2VuX3R5cGUiOiJhY2Nlc3NfdG9rZW4iLCJzZXNzaW9uX2lkIjoiNmRhOWU1NDEtZDIwYi00NjZlLTlhNGQtYmY1OTJjYWZmNzdiIiwiZXhwIjoxNjIxNTIyMzc1LCJpYXQiOjE2MjE1MTUxNzUsImlzcyI6ImJhbmtmYWNpbF9jb3JlIn0.xutmWQjk7Q_o0E2IxtImbcjiOmemuLlhwqnUc8k1nfc",
    "token_type" => "bearer",
    "refresh_token" => "ref-token",
    "expires_in" => 7200
  }

  @datetime_now ~U[2021-12-31 00:00:00.000000Z]
  @token %Token{
    access_token: @token_response["access_token"],
    expires_at: ~U[2021-12-31 02:00:00.000000Z]
  }

  setup_with_mocks([{DateTime, [:passthrough], utc_now: fn -> @datetime_now end}]) do
    mock_global(fn %{method: :post, url: @creditas_url} -> json(@token_response, status: 201) end)

    opts = [name: TokenServer, config: @config]
    {:ok, pid: start_supervised!({TokenServer, opts})}
  end

  describe "start_link/1" do
    setup do
      stop_supervised(TokenServer)
      :ok
    end

    test "raises error when there's no config" do
      assert_raise RuntimeError, ~r/key :config not found in: \[]/, fn ->
        start_supervised!({TokenServer, []})
      end
    end

    test "starts the server with a valid token" do
      name = MyCreditasTokenServer
      pid = start_supervised!({TokenServer, config: @config, name: name})

      Agent.get(pid, fn state ->
        assert state[:token] == @token
        assert state[:config] == @config
      end)

      Agent.get(name, fn state ->
        assert state[:token] == @token
        assert state[:config] == @config
      end)
    end
  end

  describe "request_new_token/1" do
    test "fails to request a new token" do
      mock_global(fn %{method: :post, url: @creditas_url} -> {:error, :timeout} end)
      assert TokenServer.request_new_token(@config) == {:error, :timeout}
    end

    test "returns error with invalid credentials" do
      error_response = %{"error" => "Invalid Credentials"}

      mock_global(fn %{method: :post, url: @creditas_url} -> json(error_response, status: 401) end)

      assert {:error, %Tesla.Env{status: 401, body: ^error_response}} =
               TokenServer.request_new_token(@config)
    end

    test "requests a new token" do
      assert TokenServer.request_new_token(@config) == {:ok, @token}
      assert_called(DateTime.utc_now())
    end
  end

  describe "get_token/1" do
    test "returns a token", %{pid: pid} do
      assert TokenServer.get_token(pid) == @token
      assert TokenServer.get_token(TokenServer) == @token
    end
  end

  describe "get_refreshed_token/2" do
    @refreshed_access_token "some access_token"
    @refreshed_token_response Map.put(@token_response, "access_token", @refreshed_access_token)
    @seconds_before_refresh 30

    test "returns error when update fails", %{pid: pid} do
      error_response = {:error, :timeout}
      mock_global(fn %{method: :post, url: @creditas_url} -> error_response end)

      expired_seconds = @token_response["expires_in"] + 1
      expired_datetime = DateTime.add(@datetime_now, expired_seconds, :second)

      with_mock DateTime, [:passthrough], utc_now: fn -> expired_datetime end do
        assert TokenServer.get_refreshed_token(pid, @seconds_before_refresh) == error_response

        assert TokenServer.get_refreshed_token(TokenServer, @seconds_before_refresh) ==
                 error_response

        assert_called(DateTime.utc_now())
      end
    end

    test "returns a token", %{pid: pid} do
      access_token = @token.access_token

      assert %Token{access_token: ^access_token} =
               change_current_time_to_get_refreshed_token(
                 pid,
                 @token_response["expires_in"] - @seconds_before_refresh - 1
               )
    end

    test "refreshes a token when current time is smaller than token expiration", %{pid: pid} do
      assert %Token{access_token: @refreshed_access_token} =
               change_current_time_to_get_refreshed_token(
                 pid,
                 @token_response["expires_in"] - @seconds_before_refresh
               )
    end

    test "refreshes a token when current time is equal as token expiration", %{pid: pid} do
      assert %Token{access_token: @refreshed_access_token} =
               change_current_time_to_get_refreshed_token(
                 pid,
                 @token_response["expires_in"]
               )
    end

    test "refreshes a token when current time is bigger than token expiration", %{pid: pid} do
      assert %Token{access_token: @refreshed_access_token} =
               change_current_time_to_get_refreshed_token(
                 pid,
                 @token_response["expires_in"] + 1
               )
    end

    defp change_current_time_to_get_refreshed_token(pid, add_seconds_to_datetime_now) do
      mock_global(fn %{method: :post, url: @creditas_url} ->
        json(@refreshed_token_response, status: 201)
      end)

      current_datetime = DateTime.add(@datetime_now, add_seconds_to_datetime_now, :second)

      with_mock DateTime, [:passthrough], utc_now: fn -> current_datetime end do
        token = TokenServer.get_refreshed_token(pid, @seconds_before_refresh)
        assert ^token = TokenServer.get_refreshed_token(pid)
        assert ^token = TokenServer.get_refreshed_token(TokenServer)
        assert ^token = TokenServer.get_refreshed_token(TokenServer, @seconds_before_refresh)
        assert_called(DateTime.utc_now())
        token
      end
    end
  end

  describe "set_token/2" do
    test "stores a token", %{pid: pid} do
      token = %Token{access_token: "123", expires_at: DateTime.utc_now()}

      :ok = TokenServer.set_token(pid, token)
      assert TokenServer.get_token(pid) == token

      :ok = TokenServer.set_token(TokenServer, token)
      assert TokenServer.get_token(TokenServer) == token
    end
  end

  describe "update_token/1" do
    test "returns error when update fails", %{pid: pid} do
      mock_global(fn %{method: :post, url: @creditas_url} -> {:error, :timeout} end)
      assert TokenServer.update_token(pid) == {:error, :timeout}
      assert TokenServer.update_token(TokenServer) == {:error, :timeout}
    end

    test "updates a token", %{pid: pid} do
      token_response = Map.put(@token_response, "access_token", "some access_token")
      expected_token = Map.put(@token, :access_token, "some access_token")

      mock_global(fn %{method: :post, url: @creditas_url} ->
        json(token_response, status: 201)
      end)

      assert TokenServer.update_token(pid) == {:ok, expected_token}
      assert TokenServer.update_token(TokenServer) == {:ok, expected_token}
    end
  end
end
