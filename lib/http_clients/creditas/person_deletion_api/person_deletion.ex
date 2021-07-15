defmodule HttpClients.Creditas.PersonDeletionApi.PersonDeletion do
  @moduledoc false

  @type t :: %__MODULE__{
          id: binary(),
          person_id: binary(),
          person_cpf: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(id person_id person_cpf)a
  defstruct ~w(id person_id person_cpf)a
end
