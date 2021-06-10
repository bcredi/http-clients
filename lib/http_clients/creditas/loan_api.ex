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

  defp build_loan(attrs) do
    %{"key" => key_attrs, "contract" => contract_attrs, "product" => product_attrs} = attrs
    key = %LoanApi.Key{type: key_attrs["type"], code: key_attrs["code"]}

    contract = %LoanApi.Contract{
      number: contract_attrs["number"],
      issuedAt: contract_attrs["issuedAt"],
      signedAt: contract_attrs["signedAt"]
    }

    product = %LoanApi.Product{type: product_attrs["type"], subtype: product_attrs["subtype"]}
    indexation = %LoanApi.Indexation{type: attrs["indexation"]["type"]}

    %LoanApi.Loan{
      key: key,
      id: attrs["id"],
      status: attrs["status"],
      creditor: attrs["creditor"],
      originator: attrs["originator"],
      underwriter: attrs["underwriter"],
      currency: attrs["currency"],
      financedAmount: attrs["financedAmount"],
      installmentsCount: attrs["installmentsCount"],
      installmentFrequency: attrs["installmentFrequency"],
      installmentFixedAmount: attrs["installmentFixedAmount"],
      firstInstallmentDueDate: attrs["firstInstallmentDueDate"],
      lastInstallmentDueDate: attrs["lastInstallmentDueDate"],
      amortizationMethod: attrs["amortizationMethod"],
      contract: contract,
      collaterals: build_collaterals(attrs["collaterals"]),
      participants: build_participants(attrs["participants"]),
      product: product,
      fees: build_fees(attrs["fees"]),
      taxes: build_taxes(attrs["taxes"]),
      interestRates: build_interest_rates(attrs["interestRates"]),
      indexation: indexation,
      insurances: build_insurances(attrs["insurances"])
    }
  end

  defp build_collaterals(collaterals) do
    Enum.map(collaterals, fn collateral -> %LoanApi.Collateral{id: collateral["id"]} end)
  end

  defp build_participants(participants) do
    Enum.map(participants, fn participant ->
      credit_score_attrs = participant["creditScore"]

      credit_score = %LoanApi.CreditScore{
        provider: credit_score_attrs["provider"],
        value: credit_score_attrs["value"]
      }

      %LoanApi.Participant{
        id: participant["id"],
        authId: participant["authId"],
        creditScore: credit_score,
        roles: participant["roles"]
      }
    end)
  end

  defp build_fees(fees) do
    Enum.map(fees, fn fee ->
      %LoanApi.Fee{type: fee["type"], payer: fee["payer"], value: fee["value"]}
    end)
  end

  defp build_taxes(taxes) do
    Enum.map(taxes, fn tax -> %LoanApi.Tax{type: tax["type"], value: tax["value"]} end)
  end

  defp build_interest_rates(interest_rates) do
    Enum.map(interest_rates, fn interest_rate ->
      %LoanApi.InterestRate{
        context: interest_rate["context"],
        frequency: interest_rate["frequency"],
        base: interest_rate["base"],
        value: interest_rate["value"]
      }
    end)
  end

  defp build_insurances(insurances) do
    Enum.map(insurances, fn insurance -> %LoanApi.Insurance{type: insurance["type"]} end)
  end

  @spec client(String.t(), String.t()) :: Tesla.Client.t()
  def client(base_url, bearer_token) do
    headers = [
      {"Authorization", "Bearer #{bearer_token}"},
      {"X-Tenant-Id", "creditasbr"},
      {"Accept", "application/vnd.creditas.v2+json"}
    ]

    middlewares = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, headers},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Retry, delay: 1_000, max_retries: 3},
      {Tesla.Middleware.Timeout, timeout: 120_000}
    ]

    Tesla.client(middlewares)
  end
end
