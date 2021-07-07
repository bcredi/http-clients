defmodule HttpClients.Underwriter.Proposal do
  @moduledoc false

  alias HttpClients.Underwriter.{Partner, Proponent}

  @type t :: %__MODULE__{
          id: binary(),
          sales_stage: String.t(),
          loan_requested_amount: Decimal.t(),
          financing_type: String.t(),
          lead_score: integer(),
          main_proponent: Proponent.t(),
          partner: Partner.t(),
          warranty_value_status: String.t(),
          warranty_region_status: String.t(),
          warranty_type_status: String.t(),
          pre_qualified: boolean(),
          lost_reason: String.t()
        }

  @derive Jason.Encoder
  defstruct ~w(id sales_stage loan_requested_amount financing_type status lead_score
               main_proponent partner warranty_value_status warranty_region_status
               warranty_type_status pre_qualified lost_reason)a
end
