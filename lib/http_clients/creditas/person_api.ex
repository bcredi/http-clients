defmodule HttpClients.Creditas.PersonApi do
  @moduledoc false

  alias HttpClients.Creditas.PersonApi.{Address, Contact, MainDocument, Person}

  @spec get_person_by_cpf(Tesla.Client.t(), String.t()) :: Person.t()
  def get_person_by_cpf(client, cpf) do
    query = "mainDocument.code=#{cpf}"

    case Tesla.get(client, "/persons", query: query) do
      {:ok, %Tesla.Env{status: 200, body: attrs}} ->
        {:ok, build_person(attrs)}

      {:ok, %Tesla.Env{} = response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_person(attrs) do
    %Person{
      fullName: attrs["fullName"],
      birthDate: attrs["birthDate"],
      contacts: build_contacts(attrs),
      addresses: build_addresses(attrs),
      mainDocument: %MainDocument{
        type: attrs["mainDocument"]["type"],
        code: attrs["mainDocument"]["code"]
      }
    }
  end

  defp build_contacts(attrs) do
    Enum.reduce(attrs["contacts"], [], fn contact, contacts ->
      [
        %Contact{
          channel: contact["channel"],
          code: contact["code"],
          type: contact["type"]
        }
        | contacts
      ]
    end)
  end

  defp build_addresses(attrs) do
    Enum.reduce(attrs["addresses"], [], fn address, addresses ->
      [
        %Address{
          type: address["type"],
          country: address["country"],
          street: address["street"],
          number: address["number"],
          zipCode: address["zipCode"],
          neighborhood: address["neighborhood"],
          complement: address["complement"]
        }
        | addresses
      ]
    end)
  end

  @spec client(String.t(), String.t()) :: Tesla.Client.t()
  def client(base_url, bearer_token) do
    headers = headers(bearer_token)

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, headers},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 120_000},
      Tesla.Middleware.Logger
    ]

    Tesla.client(middlewares)
  end

  defp headers(bearer_token) do
    [
      {"Authorization", "Bearer #{bearer_token}"},
      {"X-Tenant-Id", "creditasbr"},
      {"Accept", "application/vnd.creditas.v1+json"}
    ]
  end
end
