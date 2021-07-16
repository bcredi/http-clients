defmodule HttpClients.Creditas.PersonDeletionApi.PersonDeletion do
  @moduledoc false

  @type t :: %__MODULE__{
          id: String.t(),
          person_id: String.t(),
          person_cpf: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys ~w(id person_id person_cpf)a
  defstruct ~w(id person_id person_cpf)a
end
