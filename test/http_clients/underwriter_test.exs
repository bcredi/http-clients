defmodule HttpClients.UnderwriterTest do
  use ExUnit.Case
  import Tesla.Mock

  alias HttpClients.Underwriter
  alias HttpClients.Underwriter.Proponent

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
    @proponent %Proponent{
      birthdate: "1980-12-31",
      email: "some@email.com",
      cpf: "12345678901",
      name: "Fulano Sicrano",
      proposal_id: "some_id",
      added_by_proponent: "Joao da silva"
    }

    test "calls underwriter and creates proponent" do
      proponent_id = UUID.uuid4()
      proponents_url = "#{@base_url}/v1/proponents"
      expected_proponent = Map.put(@proponent, :id, proponent_id)

      mock(fn %{method: :post, url: ^proponents_url} ->
        json(%{data: expected_proponent}, status: 201)
      end)

      assert {:ok, ^expected_proponent} = Underwriter.create_proponent(client(), @proponent)
    end

    test "returns error when response status is not 201" do
      proponents_url = "#{@base_url}/v1/proponents"
      response_body = %{"errors" => %{"cpf" => "can't be blank"}}
      mock(fn %{method: :post, url: ^proponents_url} -> json(response_body, status: 422) end)
      proponent = Map.put(@proponent, :cpf, nil)

      assert {:error, expected_response} = Underwriter.create_proponent(client(), proponent)
      assert %Tesla.Env{body: ^response_body, status: 422} = expected_response
    end
  end

  describe "get_proponent/2" do
    test "returns a proponent" do
      proponent_id = UUID.uuid4()
      proponents_url = "#{@base_url}/v1/proponents/#{proponent_id}"

      mock(fn %{method: :get, url: ^proponents_url} ->
        json(%{"id" => proponent_id})
      end)

      assert {:ok, %Tesla.Env{body: response_body, status: 200}} =
               Underwriter.get_proponent(client(), proponent_id)

      expected_response_body = %{"id" => proponent_id}
      assert response_body == expected_response_body
    end

    test "returns error when the proponent doesn't exist" do
      proponent_id = UUID.uuid4()
      proponents_url = "#{@base_url}/v1/proponents/#{proponent_id}"

      mock(fn %{method: :get, url: ^proponents_url} ->
        %Tesla.Env{status: 404, body: %{"errors" => %{"detail" => "Not Found"}}}
      end)

      assert {:error, %Tesla.Env{body: response_body, status: 404}} =
               Underwriter.get_proponent(client(), proponent_id)

      expected_response_body = %{"errors" => %{"detail" => "Not Found"}}
      assert response_body == expected_response_body
    end
  end

  describe "update_proponent/2" do
    test "returns a proponent" do
      proponent_id = UUID.uuid4()
      email = "some@email.com"
      proponent = %Proponent{id: proponent_id, email: email}
      proponents_url = "#{@base_url}/v1/proponents/#{proponent_id}"

      mock(fn %{method: :patch, url: ^proponents_url} ->
        %Tesla.Env{status: 200, body: %{"data" => %{"id" => proponent_id, "email" => email}}}
      end)

      assert {:ok, ^proponent} = Underwriter.update_proponent(client(), proponent)
    end

    test "returns error when the proponent doesn't exist" do
      proponent_id = UUID.uuid4()
      email = "some@email.com"
      proponent = %Proponent{id: proponent_id, email: email}
      proponents_url = "#{@base_url}/v1/proponents/#{proponent_id}"

      mock(fn %{method: :patch, url: ^proponents_url} ->
        %Tesla.Env{status: 404, body: %{"errors" => %{"detail" => "Not Found"}}}
      end)

      assert {:error, %Tesla.Env{body: response_body, status: 404}} =
               Underwriter.update_proponent(client(), proponent)

      expected_response_body = %{"errors" => %{"detail" => "Not Found"}}
      assert response_body == expected_response_body
    end

    test "returns error when email is invalid" do
      proponent_id = UUID.uuid4()
      email = "invalid#email.com"
      proponent = %Proponent{id: proponent_id, email: email}
      proponents_url = "#{@base_url}/v1/proponents/#{proponent_id}"

      response_body = %{"errors" => %{"email" => ["has invalid format"]}}
      mock(fn %{method: :patch, url: ^proponents_url} -> json(response_body, status: 422) end)

      assert {:error, expected_response} = Underwriter.update_proponent(client(), proponent)
      assert %Tesla.Env{body: ^response_body, status: 422} = expected_response
    end
  end

  describe "remove_proponent/2" do
    test "returns :ok tuple" do
      proponent_id = UUID.uuid4()
      proponent = %Proponent{id: proponent_id}
      proponents_url = "#{@base_url}/v1/proponents/#{proponent_id}"

      mock(fn %{method: :delete, url: ^proponents_url} ->
        %Tesla.Env{status: 204, body: %{}}
      end)

      assert :ok = Underwriter.remove_proponent(client(), proponent)
    end

    test "returns error when the proponent doesn't exist" do
      proponent_id = UUID.uuid4()
      proponent = %Proponent{id: proponent_id}
      proponents_url = "#{@base_url}/v1/proponents/#{proponent_id}"

      mock(fn %{method: :delete, url: ^proponents_url} ->
        %Tesla.Env{status: 404, body: %{"errors" => %{"detail" => "Not Found"}}}
      end)

      assert {:error, %Tesla.Env{body: response_body, status: 404}} =
               Underwriter.remove_proponent(client(), proponent)

      assert response_body == %{"errors" => %{"detail" => "Not Found"}}
    end
  end

  defp client, do: Tesla.client([{Tesla.Middleware.BaseUrl, @base_url}, Tesla.Middleware.JSON])
end
