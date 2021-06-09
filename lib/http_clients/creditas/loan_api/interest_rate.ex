defmodule HttpClients.Creditas.LoanApi.InterestRate do
  @moduledoc false

  @type t :: %__MODULE__{
          context: String.t(),
          frequency: String.t(),
          base: integer(),
          value: Decimal.t()
        }

  @derive Jason.Encoder
  defstruct ~w(context frequency base value)a
end
