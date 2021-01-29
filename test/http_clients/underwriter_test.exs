defmodule HttpClients.UnderwriterTest do
  use ExUnit.Case
  import Tesla.Mock

  alias HttpClients.Underwriter
  alias Underwriter.Proponent

  @base_url "http://bcredi.com"
  @client_id "client-id"
  @client_secret "client-secret"

  describe "client/3" do
    test "returns a tesla client" do
      expected_configs = [
        {Tesla.Middleware.BaseUrl, :call, [@base_url]},
        {Tesla.Middleware.JSON, :call, [[]]},
        {Tesla.Middleware.Headers, :call,
         [
           [
             {"X-Ambassador-Client-ID", @client_id},
             {"X-Ambassador-Client-Secret", @client_secret}
           ]
         ]},
        {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
        {Tesla.Middleware.Timeout, :call, [[timeout: 15_000]]},
        {Tesla.Middleware.Logger, :call, [[]]},
        {Goodies.Tesla.Middleware.RequestIdForwarder, :call, [[]]}
      ]

      client = Underwriter.client(@base_url, @client_id, @client_secret)
      assert %Tesla.Client{} = client
      assert client.pre == expected_configs
    end
  end

  describe "create_proponent/2" do
    test "calls underwriter and creates proponent" do
      proponent_id = UUID.uuid4()
      proponents_url = "#{@base_url}/v1/proponents"

      mock(fn %{method: :post, url: ^proponents_url} ->
        json(%{"id" => proponent_id})
      end)

      proponent = %Proponent{
        birthdate: "1980-12-31",
        email: "some@email.com",
        cpf: "12345678901",
        name: "Fulano Sicrano",
        mobile_phone_number: "41999999999",
        proposal_id: proponent_id,
        added_by_proponent: "Joao da silva"
      }

      assert {:ok, expected_response} = Underwriter.create_proponent(client(), proponent)
      assert %Tesla.Env{body: %{"id" => ^proponent_id}, status: 200} = expected_response
    end

    test "returns error when response status is 422" do
      proponents_url = "#{@base_url}/v1/proponents"
      response_body = %{"errors" => %{"cpf" => "can't be blank"}}
      mock(fn %{method: :post, url: ^proponents_url} -> json(response_body, status: 422) end)
      proponent = %Proponent{cpf: nil}

      assert {:error, %Tesla.Env{} = expected_response} =
               Underwriter.create_proponent(client(), proponent)

      assert %Tesla.Env{body: ^response_body, status: 422} = expected_response
    end
  end

  defp client, do: Tesla.client([{Tesla.Middleware.BaseUrl, @base_url}, Tesla.Middleware.JSON])
end
