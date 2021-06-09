defmodule HttpClients.Creditas.LoanApi.Key do
  @moduledoc false

  @type t :: %__MODULE__{
          type: String.t(),
          code: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(type code)a
  defstruct ~w(type code)a
end
