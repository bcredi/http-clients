defmodule HttpClients.CustomerManagement do
    @moduledoc """
    Client for Underwriter calls
    """
    @spec get_proponent(Tesla.Client.t(), map()) :: {:error, any} | {:ok, Tesla.Env.t()}
    def create_proponent(%Tesla.Client{} = client, attrs) do
    end
end