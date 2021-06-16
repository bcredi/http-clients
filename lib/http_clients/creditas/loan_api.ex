defmodule HttpClients.Creditas.LoanApi do
  @moduledoc false

  alias HttpClients.Creditas.LoanApi

  @spec get_by_key(Tesla.Client.t(), Key.t()) :: {:error, any} | {:ok, Loan.t() | nil}
  def get_by_key(client, %LoanApi.Key{} = key) do
    query = ["key.code": key.code, "key.type": key.type]

    case Tesla.get(client, "/loans", query: query) do
      {:ok, %Tesla.Env{status: 200, body: %{"items" => [attrs]}}} -> {:ok, build_loan(attrs)}
      {:ok, %Tesla.Env{status: 200, body: %{"items" => []}}} -> {:ok, nil}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec create(Tesla.Client.t(), map()) :: {:error, any} | {:ok, Loan.t()}
  def create(client, %{} = loan_attrs) do
    case Tesla.post(client, "/loans", loan_attrs) do
      {:ok, %Tesla.Env{status: 201, body: response_body}} -> {:ok, build_loan(response_body)}
      {:ok, %Tesla.Env{} = response} -> {:error, response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_loan(attrs) do
    key = to_struct(LoanApi.Key, attrs["key"])
    contract = to_struct(LoanApi.Contract, attrs["contract"])
    product = to_struct(LoanApi.Product, attrs["product"])
    indexation = to_struct(LoanApi.Indexation, attrs["indexation"])

    LoanApi.Loan
    |> to_struct(attrs)
    |> Map.put(:key, key)
    |> Map.put(:contract, contract)
    |> Map.put(:product, product)
    |> Map.put(:indexation, indexation)
    |> Map.put(:participants, build_participants(attrs["participants"]))
    |> Map.put(:collaterals, to_struct_list(LoanApi.Collateral, attrs["collaterals"]))
    |> Map.put(:fees, to_struct_list(LoanApi.Fee, attrs["fees"]))
    |> Map.put(:taxes, to_struct_list(LoanApi.Tax, attrs["taxes"]))
    |> Map.put(:interestRates, to_struct_list(LoanApi.InterestRate, attrs["interestRates"]))
    |> Map.put(:insurances, to_struct_list(LoanApi.Insurance, attrs["insurances"]))
  end

  defp build_participants(participants) do
    Enum.map(participants, fn participant ->
      credit_score_attrs = participant["creditScore"]
      credit_score = to_struct(LoanApi.CreditScore, credit_score_attrs)

      LoanApi.Participant
      |> to_struct(participant)
      |> Map.put(:creditScore, credit_score)
    end)
  end

  defp to_struct_list(kind, values), do: Enum.map(values, &to_struct(kind, &1))

  defp to_struct(kind, attrs) do
    struct = struct(kind)

    Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end)
  end

  @spec client(String.t(), String.t()) :: Tesla.Client.t()
  def client(base_url, bearer_token) do
    headers = [
      {"Authorization", "Bearer #{bearer_token}"},
      {"X-Tenant-Id", "creditasbr"},
      {"Accept", "application/vnd.creditas.v2+json"}
    ]

    json_opts = [
      decode_content_types: ["application/vnd.creditas.v2+json"]
    ]

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, headers},
      {Tesla.Middleware.JSON, json_opts},
      {Tesla.Middleware.Logger, filter_headers: ["Authorization"]},
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 120_000}
    ]

    Tesla.client(middlewares)
  end
end
