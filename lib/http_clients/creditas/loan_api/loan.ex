defmodule CreditasAcl.LoanApi.Loan do
  @moduledoc false

  alias HttpClients.Creditas.LoanApi.{
    Collateral,
    Contract,
    Fee,
    Insurance,
    InterestRate,
    Key,
    Participant,
    Tax
  }

  @type t :: %__MODULE__{
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
          insurances: List.t(Insurance.t())
        }

  @derive Jason.Encoder
  @enforce_keys ~w()a
  defstruct ~w(key contract collaterals participants creditor originator underwriter product currency financedAmount
  installmentsCount installmentFrequency installmentFixedAmount firstInstallmentDueDate lastInstallmentDueDate fees
  taxes interestRates amortizationMethod indexation insurances)a
end
