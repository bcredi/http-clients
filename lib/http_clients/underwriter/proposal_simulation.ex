defmodule HttpClients.Underwriter.ProposalSimulation do
  @moduledoc false

  @type t :: %__MODULE__{loan_requested_amount: Decimal.t(), financing_type: String.t()}

  @derive Jason.Encoder
  defstruct ~w(loan_requested_amount financing_type)a
end
