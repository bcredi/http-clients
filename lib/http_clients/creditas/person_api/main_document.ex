defmodule HttpClients.Creditas.PersonApi.MainDocument do
  @moduledoc false

  @type t :: %__MODULE__{
          type: String.t(),
          code: String.t()
        }

  @derive Jason.Encoder
  defstruct ~w(type code)a
end
