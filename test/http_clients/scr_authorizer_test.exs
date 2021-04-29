defmodule HttpClients.ScrAuthorizerTest do
  use ExUnit.Case
  import Tesla.Mock

  alias HttpClients.ScrAuthorizer
  alias HttpClients.ScrAuthorizer.ProponentAuthorization

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
        {Tesla.Middleware.Timeout, :call, [[timeout: 30_000]]},
        {Tesla.Middleware.Logger, :call, [[]]},
        {Goodies.Tesla.Middleware.RequestIdForwarder, :call, [[]]}
      ]

      assert %Tesla.Client{pre: configs} =
               ScrAuthorizer.client(@base_url, @client_id, @client_secret)

      assert configs == expected_configs
    end
  end

  describe "create_proponent_authorization/2" do
    @term_of_use_document File.read!("#{File.cwd!()}/test/assets/test.pdf")
    @proponent_authorization %ProponentAuthorization{
      proponent_id: UUID.uuid4(),
      user_agent: "some user agent",
      ip: "8.8.8.8",
      term_of_use_document: @term_of_use_document
    }

    test "creates proponent authorization" do
      authorization_id = UUID.uuid4()
      proponent_authorization_url = "#{@base_url}/v1/proponent-authorizations"

      expected_authorization =
        @proponent_authorization
        |> Map.put(:id, authorization_id)
        |> Map.put(:term_of_use_document, nil)

      mock(fn %{method: :post, body: %Tesla.Multipart{}, url: ^proponent_authorization_url} ->
        json(%{data: expected_authorization}, status: 201)
      end)

      assert ScrAuthorizer.create_proponent_authorization(client(), @proponent_authorization) ==
               {:ok, expected_authorization}
    end

    test "returns error when authorization doesn't has some required value" do
      required_fields = ~w(proponent_id user_agent ip term_of_use_document)a

      Enum.each(required_fields, fn required_field ->
        authorization = Map.put(@proponent_authorization, required_field, nil)

        assert_raise ArgumentError, "nil is not a supported multipart value.", fn ->
          ScrAuthorizer.create_proponent_authorization(client(), authorization)
        end
      end)
    end

    test "returns error when authorization was not created" do
      authorization = Map.put(@proponent_authorization, :ip, "999.214.2.107")
      proponent_authorization_url = "#{@base_url}/v1/proponent-authorizations"
      response_body = %{"errors" => %{"ip" => "is invalid"}}

      mock(fn %{method: :post, body: %Tesla.Multipart{}, url: ^proponent_authorization_url} ->
        json(response_body, status: 422)
      end)

      assert {:error, expected_response} =
               ScrAuthorizer.create_proponent_authorization(client(), authorization)

      assert %Tesla.Env{body: ^response_body, status: 422} = expected_response
    end
  end

  defp client, do: Tesla.client([{Tesla.Middleware.BaseUrl, @base_url}, Tesla.Middleware.JSON])
end
