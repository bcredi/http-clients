defmodule HttpClients.Creditas.LoanApi.Collateral do
  @moduledoc false

  @type t :: %__MODULE__{
          id: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(id)a
  defstruct ~w(id)a
end
