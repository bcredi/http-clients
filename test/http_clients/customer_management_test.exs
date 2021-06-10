defmodule HttpClients.CustomerManagementTest do
  use ExUnit.Case
  import Tesla.Mock

  alias HttpClients.CustomerManagement

  @base_url "http://bcredi.com"
  @client_id "client-id"
  @client_secret "client-secret"

  describe "client/3" do
    test "returns a tesla client" do
      expected_client = %Tesla.Client{
        adapter: nil,
        fun: nil,
        post: [],
        pre: [
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
          {Tesla.Middleware.Logger, :call, [[filter_headers: ["Authorization"]]]},
          {Goodies.Tesla.Middleware.RequestIdForwarder, :call, [[]]}
        ]
      }

      client = CustomerManagement.client(@base_url, @client_id, @client_secret)
      assert client == expected_client
    end
  end

  describe "get_proposal/2" do
    test "returns a proposal" do
      proposal_id = UUID.uuid4()
      proposals_url = "#{@base_url}/v1/proposals/#{proposal_id}"

      mock(fn %{method: :get, url: ^proposals_url} ->
        json(%{"id" => proposal_id})
      end)

      assert {:ok, %Tesla.Env{body: response_body, status: 200}} =
               CustomerManagement.get_proposal(client(), proposal_id)

      assert response_body == %{"id" => proposal_id}
    end

    test "returns an error when proposal doesn't exist" do
      proposal_id = UUID.uuid4()
      proposals_url = "#{@base_url}/v1/proposals/#{proposal_id}"

      mock(fn %{method: :get, url: ^proposals_url} ->
        %Tesla.Env{status: 404, body: %{"errors" => %{"detail" => "Not Found"}}}
      end)

      assert {:error, %Tesla.Env{body: response_body, status: 404}} =
               CustomerManagement.get_proposal(client(), proposal_id)

      assert response_body == %{"errors" => %{"detail" => "Not Found"}}
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
               CustomerManagement.get_proponent(client(), proponent_id)

      assert response_body == %{"id" => proponent_id}
    end

    test "returns an error when proponent doesn't exist" do
      proponent_id = UUID.uuid4()
      proponents_url = "#{@base_url}/v1/proponents/#{proponent_id}"

      mock(fn %{method: :get, url: ^proponents_url} ->
        %Tesla.Env{status: 404, body: %{"errors" => %{"detail" => "Not Found"}}}
      end)

      assert {:error, %Tesla.Env{body: response_body, status: 404}} =
               CustomerManagement.get_proponent(client(), proponent_id)

      assert response_body == %{"errors" => %{"detail" => "Not Found"}}
    end
  end

  defp client, do: Tesla.client([{Tesla.Middleware.BaseUrl, @base_url}, Tesla.Middleware.JSON])
end
