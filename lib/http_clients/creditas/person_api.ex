defmodule HttpClients.Creditas.PersonApi do
  @moduledoc false

  alias HttpClients.Creditas.PersonApi.{Address, Contact, MainDocument, Person}

  @spec get_person_by_cpf(Tesla.Client.t(), String.t()) :: {:error, any} | {:ok, Person.t()}
  def get_person_by_cpf(client, cpf) do
    query = "mainDocument.code=#{cpf}"

    case Tesla.get(client, "/persons", query: query) do
      {:ok, %Tesla.Env{status: 200, body: attrs}} -> {:ok, build_person(attrs)}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec create_person(Tesla.Client.t(), Person.t()) :: {:error, any} | {:ok, Person.t()}
  def create_person(client, %Person{} = person) do
    case Tesla.post(client, "/persons", person) do
      {:ok, %Tesla.Env{status: 201, body: attrs}} -> {:ok, build_person(attrs)}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec update_person(Tesla.Client.t(), Person.t(), map()) :: {:ok, Person.t()} | {:error, any()}
  def update_person(client, %Person{id: person_id, version: current_version}, attrs) do
    query = "currentVersion=#{current_version}"

    case(Tesla.patch(client, "/persons/#{person_id}", attrs, query: query)) do
      {:ok, %Tesla.Env{status: 200, body: updated_attrs}} -> {:ok, build_person(updated_attrs)}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_person(attrs) do
    %Person{
      id: attrs["id"],
      fullName: attrs["fullName"],
      birthDate: attrs["birthDate"],
      version: attrs["version"],
      contacts: build_contacts(attrs["contacts"] || []),
      addresses: build_addresses(attrs["addresses"] || []),
      mainDocument: build_main_document(attrs["mainDocument"])
    }
  end

  defp build_main_document(main_document) do
    %MainDocument{
      type: main_document["type"],
      code: main_document["code"]
    }
  end

  defp build_contacts(contacts) do
    Enum.map(contacts, fn contact ->
      %Contact{
        channel: contact["channel"],
        code: contact["code"],
        type: contact["type"]
      }
    end)
  end

  defp build_addresses(addresses) do
    Enum.map(addresses, fn address ->
      %Address{
        type: address["type"],
        country: address["country"],
        street: address["street"],
        number: address["number"],
        zipCode: address["zipCode"],
        neighborhood: address["neighborhood"],
        complement: address["complement"]
      }
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
