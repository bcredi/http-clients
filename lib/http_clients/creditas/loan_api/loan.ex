defmodule HttpClients.Creditas.LoanApi.Loan do
  @moduledoc false

  alias HttpClients.Creditas.LoanApi.{
    Collateral,
    Contract,
    Fee,
    Indexation,
    Insurance,
    InterestRate,
    Key,
    Participant,
    Product,
    Tax
  }

  @type t :: %__MODULE__{
          id: String.t(),
          key: Key.t(),
          contract: Contract.t(),
          product: Product.t(),
          indexation: Indexation.t(),
          creditor: String.t(),
          originator: String.t(),
          underwriter: String.t(),
          currency: String.t(),
          financedAmount: Decimal.t(),
          installmentsCount: integer(),
          installmentFrequency: String.t(),
          installmentFixedAmount: Decimal.t(),
          firstInstallmentDueDate: Date.t(),
          lastInstallmentDueDate: Date.t(),
          amortizationMethod: String.t(),
          collaterals: List.t(Collateral.t()),
          participants: List.t(Participant.t()),
          fees: List.t(Fee.t()),
          taxes: List.t(Tax.t()),
          interestRates: List.t(InterestRate.t()),
          insurances: List.t(Insurance.t()),
          status: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(key creditor originator underwriter product currency financedAmount installmentsCount
                installmentFrequency firstInstallmentDueDate lastInstallmentDueDate interestRates amortizationMethod
                indexation contract collaterals participants)a

  defstruct ~w(id status key contract collaterals participants creditor originator underwriter product currency
            financedAmount installmentsCount installmentFrequency installmentFixedAmount firstInstallmentDueDate
            lastInstallmentDueDate fees taxes interestRates amortizationMethod indexation insurances)a
end
