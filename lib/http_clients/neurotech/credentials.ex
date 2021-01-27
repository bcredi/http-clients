defmodule HttpClients.Neurotech.Credentials do
  @moduledoc false
  @type t :: %__MODULE__{
          login: String.t(),
          password: String.t()
        }
  defstruct [:login, :password]
end
