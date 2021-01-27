defmodule HttpClients.Neurotech.Score do
  @moduledoc false

  @type t :: %__MODULE__{
          score: integer(),
          positive_analysis: String.t(),
          negative_analysis: String.t()
        }

  defstruct [:score, :positive_analysis, :negative_analysis]
end
