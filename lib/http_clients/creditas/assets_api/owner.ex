defmodule HttpClients.Creditas.AssetsApi.Owner do
  @moduledoc false
  alias HttpClients.Creditas.AssetsApi.Person

  @type t :: %__MODULE__{
          person: Person.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(person)a
  defstruct ~w(person)a
end
