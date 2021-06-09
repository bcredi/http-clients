defmodule HttpClients.Creditas.LoanApi.CreditScore do
  @moduledoc false

  @type t :: %__MODULE__{
          provider: String.t(),
          value: String.t()
        }

  @derive Jason.Encoder
  defstruct ~w(provider value)a
end
