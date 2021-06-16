defmodule HttpClients.FacebookPixelTest do
  use ExUnit.Case
  import Tesla.Mock

  alias HttpClients.FacebookPixel

  @base_url "https://graph.facebook.com/v11.0"

  describe "client/?" do
    test "builds a client" do
      expected_client = %Tesla.Client{
        adapter: nil,
        fun: nil,
        post: [],
        pre: [
          {Tesla.Middleware.BaseUrl, :call, [@base_url]},
          {Tesla.Middleware.JSON, :call, [[]]},
          {Tesla.Middleware.Retry, :call, [[delay: 1000, max_retries: 3]]},
          {Tesla.Middleware.Timeout, :call, [[timeout: 15_000]]},
          {Tesla.Middleware.Logger, :call, [[]]}
        ]
      }

      assert FacebookPixel.client(@base_url) == expected_client
    end
  end

  describe "pixel_event/?" do
    test "sends event" do
      pixel_id = "1234567989654321"
      access_token = "some_access_token"

      payload = %{
        "data" => [
          %{
            "event_name" => "Purchase",
            "event_time" => 1_623_872_941,
            "action_source" => "system_generated",
            "user_data" => %{
              "em" => [
                # // SHA256
                "7b17fb0bd173f625b58636fb796407c22b3d16fc78302d79f0fd30c2fc2fc068"
              ],
              "ph" => [
                # // SHA256
                "83ae758b6458c04046a5678030f970301fd76ad0cf52c3a0e8f146acca1023cc"
              ]
            },
            "custom_data" => %{
              "currency" => "BRL",
              "value" => "142.52"
            }
          }
        ]
      }

      url = "#{@base_url}/#{pixel_id}/events?access_token=#{access_token}"
      response = %Tesla.Env{status: 200, body: %{}}
      mock(fn %{method: :post, url: ^url} -> {:ok, response} end)

      assert FacebookPixel.send_event(client(), access_token, pixel_id, payload) ==
               {:ok, response}
    end
  end

  defp client, do: Tesla.client([{Tesla.Middleware.BaseUrl, @base_url}, Tesla.Middleware.JSON])
end
