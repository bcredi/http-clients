defmodule HttpClients.Neurotech.RequestTest do
  use ExUnit.Case
  import Tesla.Mock

  import HttpClients.Fixtures.Neurotech
  alias HttpClients.Neurotech.{Credentials, Request}

  describe "submit/2" do
    test "request with valid inputs returns successful Tesla response" do
      inputs = %{
        "PROP_POLITICA" => "BACEN_SCR",
        "PROP_BACEN_CPFCNPJ" => "012345678"
      }

      request = %Request{
        inputs: inputs,
        transaction_id: 420,
        credentials: credentials()
      }

      neurotech_response = bacen_response(:success)
      mock(fn %{url: "/submit", method: :post} -> json(neurotech_response) end)

      assert {:ok, %Tesla.Env{status: 200, body: %{"StatusCode" => "0100"}}} =
               Request.submit(client(), request)
    end

    test "request with invalid inputs returns function clause error" do
      inputs = %{}

      request = %Request{
        inputs: inputs,
        transaction_id: 420,
        credentials: credentials()
      }

      assert_raise FunctionClauseError, ~r(no function clause matching in), fn ->
        Request.submit(client(), request)
      end
    end

    defp client, do: Tesla.client([Tesla.Middleware.JSON])
    defp credentials, do: %Credentials{login: "some_login", password: "some_passw0rd"}
  end
end
