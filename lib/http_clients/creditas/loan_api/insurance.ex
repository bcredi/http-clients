defmodule HttpClients.Creditas.LoanApi.Insurance do
  @moduledoc false

  @type t :: %__MODULE__{
          company: String.t(),
          type: String.t(),
          policyNumber: String.t(),
          startDate: Date.t(),
          endDate: Date.t()
        }

  @derive Jason.Encoder
  defstruct ~w(company type policyNumber startDate endDate)a
end
