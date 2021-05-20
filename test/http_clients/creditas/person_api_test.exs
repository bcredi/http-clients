defmodule HttpClients.Creditas.PersonApiTest do
  use ExUnit.Case

  import Tesla.Mock

  alias HttpClients.Creditas.PersonApi
  alias HttpClients.Creditas.PersonApi.{MainDocument, Person}

  describe "client/2" do
    @base_url "https://api.creditas.io/persons"
    @bearer_token "some_jwt_token"
    @headers [
      {"Authorization", "Bearer #{@bearer_token}"},
      {"X-Tenant-Id", "creditasbr"},
      {"Accept", "application/vnd.creditas.v1+json"}
    ]

    test "returns a tesla client" do
      expected_configs = [
        {Tesla.Middleware.BaseUrl, :call, [@base_url]},
        {Tesla.Middleware.Headers, :call, [@headers]},
        {Tesla.Middleware.JSON, :call, [[]]},
        {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
        {Tesla.Middleware.Timeout, :call, [[timeout: 120_000]]},
        {Tesla.Middleware.Logger, :call, [[]]}
      ]

      assert %Tesla.Client{pre: ^expected_configs} = PersonApi.client(@base_url, @bearer_token)
    end
  end

  describe "get_person/?" do
    @cpf "45658265002"
    @response_body %{
      "fullName" => "requested",
      "birthDate" => "10-10-1990",
      "mainDocument" => %{
        "type" => "CPF",
        "code" => @cpf
      }
    }

    test "returns person" do
      query = "mainDocument.code=#{@cpf}"

      mock(fn %{url: "/persons", method: :get, query: ^query} ->
        %Tesla.Env{status: 200, body: @response_body}
      end)

      assert {:ok,
              %Person{
                fullName: "requested",
                birthDate: "10-10-1990",
                mainDocument: %MainDocument{
                  type: "CPF",
                  code: @cpf
                }
              }} == PersonApi.get_person(%Tesla.Client{}, @cpf)
    end
  end
end
