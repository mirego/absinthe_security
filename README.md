<div align="center">
  <img src="https://github.com/mirego/absinthe_security/assets/11348/3814bf39-6a9d-4e72-9029-8e66b0b9f761" width="700" />
  <p><br /><code>AbsintheSecurity</code> provides utilities to improve the security posture of APIs built with <a href="https://absinthe-graphql.org/">Absinthe GraphQL</a>.</p>
  <a href="https://github.com/mirego/absinthe_security/actions/workflows/ci.yaml?branch=main"><img src="https://github.com/mirego/absinthe_security/actions/workflows/ci.yaml/badge.svg?branch=main" /></a>
  <a href="https://hex.pm/packages/absinthe_security"><img src="https://img.shields.io/hexpm/v/absinthe_security.svg" /></a>
</div>

## Description

This library is designed to enhance the security of your GraphQL API built with Absinthe by providing convenient utilities for query validation.

***Directive Limit Validation***: Ensure GraphQL queries don't contain an excessive number of directives, preventing potential security vulnerabilities.

***Alias Limit Validation***: Validate queries to ensure they don't use an excessive number of aliases, promoting efficient and maintainable code.

***Query Depth Validation***: Guard against overly nested queries by validating the depth of GraphQL queries, mitigating potential performance issues.

***Disable Field Suggestions***: Remove field suggestions from error messages to protect against *field fuzzing* as a method of retrieving the schema without using introspection.

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
