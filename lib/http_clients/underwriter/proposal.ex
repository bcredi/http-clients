defmodule HttpClients.Underwriter.Proposal do
  @moduledoc false

  alias HttpClients.Underwriter.{CreditAnalysis, Partner, Proponent, ProposalSimulation}

  @type t :: %__MODULE__{
          id: binary(),
          sales_stage: String.t(),
          lost_reason: String.t(),
          status: String.t(),
          blearning_lead_score: integer(),
          main_proponent: Proponent.t(),
          partner: Partner.t(),
          credit_analysis: CreditAnalysis.t(),
          proposal_simulation: ProposalSimulation.t()
        }

  @derive Jason.Encoder
  defstruct ~w(id sales_stage lost_reason status blearning_lead_score main_proponent partner credit_analysis
    proposal_simulation)a
end
