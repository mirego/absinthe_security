<div align="center">
  <img src="https://github.com/mirego/absinthe_security/assets/11348/3814bf39-6a9d-4e72-9029-8e66b0b9f761" width="700" />
  <p><br /><code>AbsintheSecurity</code> provides utilities to improve the security posture of APIs built with <a href="https://absinthe-graphql.org/">Absinthe GraphQL</a>.</p>
  <a href="https://github.com/mirego/absinthe_security/actions/workflows/ci.yaml?branch=main"><img src="https://github.com/mirego/absinthe_security/actions/workflows/ci.yaml/badge.svg?branch=main" /></a>
  <a href="https://hex.pm/packages/absinthe_security"><img src="https://img.shields.io/hexpm/v/absinthe_security.svg" /></a>
</div>

## Installation

Add `absinthe_security` to the `deps` function in your project’s `mix.exs` file:

```elixir
defp deps do
  [
    {:absinthe_security, "~> 0.1"}
  ]
end
```

Then run `mix do deps.get, deps.compile` inside your project’s directory.

## Usage

First, initialize `Absinthe.Plug` with a custom configuration:

```elixir
forward("/graphql",
  to: Absinthe.Plug,
  init_opts: MyAppGraphQL.configuration()
)
```

Your custom configuration (with all of `AbsintheSecurity`’s checks) might look like this:

```elixir
defmodule MyAppGraphQL do
  def configuration do
    [schema: MyAppGraphQL.Schema, pipeline: {__MODULE__, :absinthe_pipeline}]
  end

  def absinthe_pipeline(config, options) do
    config
    |> Absinthe.Plug.default_pipeline(options)
    |> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Complexity.Result, AbsintheSecurity.Phase.IntrospectionCheck)
    |> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Result, AbsintheSecurity.Phase.FieldSuggestionsCheck)
    |> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Complexity.Result, AbsintheSecurity.Phase.MaxAliasesCheck)
    |> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Complexity.Result, AbsintheSecurity.Phase.MaxDepthCheck)
    |> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Complexity.Result, AbsintheSecurity.Phase.MaxDirectivesCheck)
  end
end
```

### `AbsintheSecurity.Phase.IntrospectionCheck`

Disable schema introspection queries at runtime.

#### Configuration

```elixir
config :absinthe_security, AbsintheSecurity.Phase.IntrospectionCheck,
  enable_introspection: System.get_env("GRAPHQL_ENABLE_INTROSPECTION")
```

#### Pipeline

```elixir
|> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Complexity.Result, AbsintheSecurity.Phase.IntrospectionCheck)
```

#### Reference

<https://docs.escape.tech/vulnerabilities/information_disclosure/introspection_enabled>

### `AbsintheSecurity.Phase.DisableFieldSuggestions`

Disable field suggestions in responses at runtime.

#### Configuration

```elixir
config :absinthe_security, AbsintheSecurity.Phase.FieldSuggestionsCheck,
  enable_field_suggestions: System.get_env("GRAPHQL_ENABLE_FIELD_SUGGESTIONS")
```

#### Pipeline

```elixir
|> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Result, AbsintheSecurity.Phase.FieldSuggestionsCheck)
```

#### Reference

<https://docs.escape.tech/vulnerabilities/information_disclosure/graphql_field_suggestion>

### `AbsintheSecurity.Phase.MaxAliasesCheck`

Restrict the number of aliases that can be used in queries.

#### Configuration

```elixir
config :absinthe_security, AbsintheSecurity.Phase.MaxAliasesCheck,
  max_alias_count: 100
```

#### Pipeline

```elixir
|> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Complexity.Result, AbsintheSecurity.Phase.MaxAliasesCheck)
```

#### Reference

<https://docs.escape.tech/vulnerabilities/resource_limitation/graphql_alias_limit>

### `AbsintheSecurity.Phase.MaxDepthCheck`

Restrict the depth level that can be used in queries.

#### Configuration

```elixir
config :absinthe_security, AbsintheSecurity.Phase.MaxDepthCheck,
  max_depth_count: 100
```

#### Pipeline

```elixir
|> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Complexity.Result, AbsintheSecurity.Phase.MaxDepthCheck)
```

#### Reference

<https://docs.escape.tech/vulnerabilities/resource_limitation/graphql_depth_limit>

### `AbsintheSecurity.Phase.MaxDirectivesCheck`

Restrict the number of directives that can be used in queries.

#### Configuration

```elixir
config :absinthe_security, AbsintheSecurity.Phase.MaxDirectivesCheck,
  max_directive_count: 100
```

#### Pipeline

```elixir
|> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Complexity.Result, AbsintheSecurity.Phase.MaxDirectivesCheck)
```

#### Reference

<https://docs.escape.tech/vulnerabilities/resource_limitation/graphql_directive_overload>

## License

`AbsintheSecurity` is © 2023 [Mirego](https://www.mirego.com) and may be freely distributed under the [New BSD license](http://opensource.org/licenses/BSD-3-Clause). See the [`LICENSE.md`](https://github.com/mirego/absinthe_security/blob/main/LICENSE.md) file.

## About Mirego

[Mirego](https://www.mirego.com) is a team of passionate people who believe that work is a place where you can innovate and have fun. We’re a team of [talented people](https://life.mirego.com) who imagine and build beautiful Web and mobile applications. We come together to share ideas and [change the world](http://www.mirego.org).

We also [love open-source software](https://open.mirego.com) and we try to give back to the community as much as we can.
