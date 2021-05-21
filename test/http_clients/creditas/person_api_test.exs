defmodule HttpClients.Creditas.PersonApiTest do
  use ExUnit.Case

  import Tesla.Mock

  alias HttpClients.Creditas.PersonApi
  alias HttpClients.Creditas.PersonApi.{Address, Contact, MainDocument, Person}

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

  describe "get_person_by_cpf/2" do
    @client %Tesla.Client{}
    @cpf "45658265002"
    @query "mainDocument.code=#{@cpf}"
    @response_body %{
      "fullName" => "Fulano Sicrano",
      "birthDate" => "10-10-1990",
      "mainDocument" => %{
        "type" => "CPF",
        "code" => @cpf
      },
      "contacts" => [
        %{
          "channel" => "PHONE",
          "code" => "55998788454",
          "type" => "PERSONAL"
        },
        %{
          "channel" => "PHONE",
          "code" => "55998788888",
          "type" => "PERSONAL"
        }
      ],
      "addresses" => [
        %{
          "type" => "HOME",
          "country" => "BR"
        },
        %{
          "type" => "BILLING",
          "country" => "BR",
          "street" => "Av de bill",
          "number" => "2020",
          "zipCode" => "81810111",
          "neighborhood" => "Centro",
          "complement" => "apto 123"
        }
      ]
    }

    test "returns person" do
      mock(fn %{url: "/persons", method: :get, query: @query} ->
        %Tesla.Env{status: 200, body: @response_body}
      end)

      expected_person = %Person{
        fullName: "Fulano Sicrano",
        birthDate: "10-10-1990",
        mainDocument: %MainDocument{type: "CPF", code: @cpf},
        contacts: [
          %Contact{
            channel: "PHONE",
            code: "55998788454",
            type: "PERSONAL"
          },
          %Contact{
            channel: "PHONE",
            code: "55998788888",
            type: "PERSONAL"
          }
        ],
        addresses: [
          %Address{
            country: "BR",
            type: "HOME"
          },
          %Address{
            complement: "apto 123",
            country: "BR",
            neighborhood: "Centro",
            number: "2020",
            street: "Av de bill",
            type: "BILLING",
            zipCode: "81810111"
          }
        ]
      }

      assert PersonApi.get_person_by_cpf(@client, @cpf) == {:ok, expected_person}
    end

    test "returns error when request fails" do
      mock(fn %{url: "/persons", method: :get, query: @query} -> %Tesla.Env{status: 400} end)
      assert PersonApi.get_person_by_cpf(@client, @cpf) == {:error, %Tesla.Env{status: 400}}
    end

    test "returns error when does not respond" do
      mock(fn %{url: "/persons", method: :get, query: @query} -> {:error, :timeout} end)
      assert PersonApi.get_person_by_cpf(@client, @cpf) == {:error, :timeout}
    end
  end
end
