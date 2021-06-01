defmodule HttpClients.Creditas.AssetApi.Person do
  @moduledoc false

  @type t :: %__MODULE__{
          id: binary(),
          version: integer()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(id version)a
  defstruct ~w(id version)a
end
