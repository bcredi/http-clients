defmodule HttpClients.Underwriter.Proponent do
  @moduledoc false

  @type t :: %__MODULE__{
          id: binary(),
          birthdate: String.t(),
          email: String.t(),
          cpf: String.t(),
          name: String.t(),
          mobile_phone_number: String.t(),
          proposal_id: binary(),
          added_by_proponent: String.t(),
          serial_id: integer(),
          id_validation_status: String.t(),
          bacen_score: integer()
        }

  @derive Jason.Encoder
  defstruct ~w(id birthdate email cpf name mobile_phone_number proposal_id added_by_proponent serial_id bacen_score
    id_validation_status)a
end
