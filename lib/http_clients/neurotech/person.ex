defmodule HttpClients.Neurotech.Person do
  @moduledoc false
  @type t :: %__MODULE__{
          cpf: String.t(),
          birthdate: Date.t(),
          name: String.t()
        }
  defstruct [:cpf, :birthdate, :name]
end
