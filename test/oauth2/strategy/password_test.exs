defmodule OAuth2.Strategy.PasswordTest do
  use ExUnit.Case, async: true

  alias OAuth2.Strategy.Password
  test "it works" do
    opts = [
      client_id: "client_id", client_secret: "secret"
    ]
    client = Password.init(opts)
    assert client.__struct__    == OAuth2.Client
    assert client.strategy      == Password
    assert client.client_id     == "client_id"
    assert client.client_secret == "secret"
    assert client.authorize_url == "/oauth/authorize"
    assert client.token_url     == "/oauth/token"
  end
end