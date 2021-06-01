defmodule HttpClients.Creditas.AssetApi.Owner do
  @moduledoc false
  alias HttpClients.Creditas.AssetApi.Person

  @type t :: %__MODULE__{
          person: Person.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(person)a
  defstruct ~w(person)a
end
