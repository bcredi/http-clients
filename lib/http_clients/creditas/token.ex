defmodule HttpClients.Creditas.Token do
  @moduledoc false

  @type t :: %__MODULE__{
          access_token: String.t(),
          expires_at: DateTime.t()
        }

  @enforce_keys ~w(access_token expires_at)a
  defstruct ~w(access_token expires_at)a
end
