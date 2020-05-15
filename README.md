# Ex_OAuth2

> An Elixir OAuth2 Client based on OAuth2

## Install

```elixir
# mix.exs

def application do
  # Add the application to your list of applications.
  # This will ensure that it will be included in a release.
  [applications: [:logger, :ex_oauth2]]
end

defp deps do
  # Add the dependency
  [{:ex_oauth2, "~> 2.0"}]
end
```

## Configure a serializer

This library can be configured to handle encoding and decoding requests and
responses automatically based on the `accept` and/or `content-type` headers.

If you need to handle various MIME types, you can simply register serializers like so:

```elixir
ExOAuth2.Client.put_serializer(client, "application/vnd.api+json", Jason)
ExOAuth2.Client.put_serializer(client, "application/xml", MyApp.Parsers.XML)
```

The modules are expected to export `encode!/1` and `decode!/1`.

```elixir
defmodule MyApp.Parsers.XML do
  def encode!(data), do: # ...
  def decode!(binary), do: # ...
end
```

## Debug mode

Sometimes it's handy to see what's coming back from the response when getting
a token. You can configure Ex_OAuth2 to output the response like so:

```elixir
config :ex_oauth2, debug: true
```

## Usage

Current implemented strategies:

- Authorization Code
- Password
- Client Credentials

### Authorization Code Flow (AuthCode Strategy)

```elixir
# Initialize a client with client_id, client_secret, site, and redirect_uri.
# The strategy option is optional as it defaults to `OAuth2.Strategy.AuthCode`.

client = ExOAuth2.Client.new([
  strategy: ExOAuth2.Strategy.AuthCode, #default
  client_id: "client_id",
  client_secret: "abc123",
  site: "https://auth.example.com",
  redirect_uri: "https://example.com/auth/callback"
])

# Generate the authorization URL and redirect the user to the provider.
ExOAuth2.Client.authorize_url!(client)
# => "https://auth.example.com/oauth/authorize?client_id=client_id&redirect_uri=https%3A%2F%2Fexample.com%2Fauth%2Fcallback&response_type=code"

# Use the authorization code returned from the provider to obtain an access token.
client = ExOAuth2.Client.get_token!(client, code: "someauthcode")

# Use the access token to make a request for resources
resource = ExOAuth2.Client.get!(client, "/api/resource").body
```

### Client Credentials Flow

Getting an initial access token:

```elixir
# Initializing a client with the strategy `ExOAuth2.Strategy.ClientCredentials`

client = ExOAuth2.Client.new([
  strategy: ExOAuth2.Strategy.ClientCredentials,
  client_id: "client_id",
  client_secret: "abc123",
  site: "https://auth.example.com"
])

# Request a token from with the newly created client
# Token will be stored inside the `%OAuth2.Client{}` struct (client.token)
client = ExOAuth2.Client.get_token!(client)

# client.token contains the `%ExOAuth2.AccessToken{}` struct

# raw access token
access_token = client.token.access_token
```

Refreshing an access token:

```elixir
# raw refresh token - use a client with `ExOAuth2.Strategy.Refresh` for refreshing the token
refresh_token = client.token.refresh_token

refresh_client = ExOAuth2.Client.new([
  strategy: ExOAuth2.Strategy.Refresh,
  client_id: "client_id",
  client_secret: "abc123",
  site: "https://auth.example.com",
  params: %{"refresh_token" => refresh_token}
])

# refresh_client.token contains the `%ExOAuth2.AccessToken{}` struct again
refresh_client = ExOAuth2.Client.get_token!(refresh_client)
```

## Write Your Own Strategy

Here's an example strategy for GitHub:

```elixir
defmodule GitHub do
  use ExOAuth2.Strategy

  # Public API

  def client do
    ExOAuth2.Client.new([
      strategy: __MODULE__,
      client_id: System.get_env("GITHUB_CLIENT_ID"),
      client_secret: System.get_env("GITHUB_CLIENT_SECRET"),
      redirect_uri: "http://myapp.com/auth/callback",
      site: "https://api.github.com",
      authorize_url: "https://github.com/login/oauth/authorize",
      token_url: "https://github.com/login/oauth/access_token"
    ])
    |> ExOAuth2.Client.put_serializer("application/json", Jason)
  end

  def authorize_url! do
    ExOAuth2.Client.authorize_url!(client(), scope: "user,public_repo")
  end

  # you can pass options to the underlying http library via `opts` parameter
  def get_token!(params \\ [], headers \\ [], opts \\ []) do
    ExOAuth2.Client.get_token!(client(), params, headers, opts)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    ExOAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("accept", "application/json")
    |> ExOAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
```

Here's how you'd use the example GitHub strategy:

Generate the authorize URL and redirect the client for authorization.

```elixir
GitHub.authorize_url!
```

Capture the `code` in your callback route on your server and use it to obtain an access token.

```elixir
client = GitHub.get_token!(code: code)
```

Use the access token to access desired resources.

```elixir
user = ExOAuth2.Client.get!(client, "/user").body

# Or
case ExOAuth2.Client.get(client, "/user") do
  {:ok, %ExOAuth2.Response{body: user}} ->
    user
  {:error, %ExOAuth2.Response{status_code: 401, body: body}} ->
    Logger.error("Unauthorized token")
  {:error, %ExOAuth2.Error{reason: reason}} ->
    Logger.error("Error: #{inspect reason}")
end
```

## License

The MIT License (MIT)

Copyright (c) 2020 Alexandre Juca

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
