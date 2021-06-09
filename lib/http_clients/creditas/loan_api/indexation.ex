defmodule HttpClients.Creditas.LoanApi.Indexation do
  @moduledoc false

  @type t :: %__MODULE__{
          type: String.t(),
          inflationIndexType: String.t()
        }

  @derive Jason.Encoder
  defstruct ~w(type inflationIndexType)a
end
