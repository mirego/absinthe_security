<div align="center">
  <img src="https://user-images.githubusercontent.com/11348/75812982-32921e80-5d5d-11ea-9c3b-ad46fd6005f9.png" width="500" />
  <br /><br />
  <code>AbsintheSecurity</code> provides security utilities to validate a GraphQL query before executing it.
  <a href="https://github.com/mirego/absinthe_security/actions?query=workflow%3ACI+branch%3Amain"><img src="https://github.com/mirego/absinthe_security/workflows/CI/badge.svg?branch=main" /></a>
  <a href="https://hex.pm/packages/absinthe_security"><img src="https://img.shields.io/hexpm/v/absinthe_security.svg" /></a>
</div>

## Installation

### Project dependency

Add `absinthe_security` to the `deps` function in your project’s `mix.exs` file:

```elixir
defp deps do
  [
    {:absinthe_security, "~> 1.0"}
  ]
end
```

Then run `mix do deps.get, deps.compile` inside your project’s directory.

## Requirements

- [Git](https://git-scm.com)
- [Elixir](https://elixir-lang.org/) ~1.14

## License

`AbsintheSecurity` is © 2023 [Mirego](https://www.mirego.com) and may be freely distributed under the [New BSD license](http://opensource.org/licenses/BSD-3-Clause). See the [`LICENSE.md`](https://github.com/mirego/absinthe_security/blob/main/LICENSE.md) file.

## About Mirego

[Mirego](https://www.mirego.com) is a team of passionate people who believe that work is a place where you can innovate and have fun. We’re a team of [talented people](https://life.mirego.com) who imagine and build beautiful Web and mobile applications. We come together to share ideas and [change the world](http://www.mirego.org).

We also [love open-source software](https://open.mirego.com) and we try to give back to the community as much as we can.
