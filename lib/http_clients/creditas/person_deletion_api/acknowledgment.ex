defmodule HttpClients.Creditas.PersonDeletionApi.Acknowledgment do
  @moduledoc false

  @type t :: %__MODULE__{
          person_deletion_id: String.t(),
          system_name: String.t(),
          status: String.t(),
          not_confirmed_reason: String.t()
        }

  @derive Jason.Encoder
  @enforce_keys [:person_deletion_id, :system_name]
  defstruct [:system_name, :person_deletion_id, :not_confirmed_reason, status: "CONFIRMED"]
end
