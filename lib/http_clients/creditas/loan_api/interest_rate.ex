defmodule HttpClients.Creditas.LoanApi.InterestRate do
  @moduledoc false

  @type t :: %__MODULE__{
          context: String.t(),
          frequency: String.t(),
          base: integer(),
          value: Decimal.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w()a
  defstruct ~w(context frequency base value)a
end
