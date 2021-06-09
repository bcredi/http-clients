defmodule HttpClients.Creditas.LoanApi.Tax do
  @moduledoc false

  @type t :: %__MODULE__{
          type: String.t(),
          value: Decimal.t()
        }

  @derive Jason.Encoder
  defstruct ~w(type value)a
end
