defmodule HttpClients.Creditas.LoanApi.Fee do
  @moduledoc false

  @type t :: %__MODULE__{
          type: String.t(),
          payer: String.t(),
          value: integer()
        }

  @derive Jason.Encoder
  defstruct ~w(type payer value)a
end
