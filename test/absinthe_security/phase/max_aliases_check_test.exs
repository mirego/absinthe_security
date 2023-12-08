defmodule AbsintheSecurity.Phase.MaxAliasesCheckTest do
  use AbsintheSecurityTest.AbsinthePhaseCase,
    phase: AbsintheSecurity.Phase.MaxAliasesCheck,
    schema: __MODULE__.Schema,
    async: true

  defmodule Schema do
    @moduledoc false
    use Absinthe.Schema

    query do
      field :union_object, list_of(:search_result) do
        resolve(fn _, _ -> {:ok, :foo} end)
      end

      field :quux_object, :quux do
      end
    end

    union :search_result do
      types([:foo, :quux])

      resolve_type(fn
        :foo, _ -> :foo
        :quux, _ -> :quux
      end)
    end

    object :foo do
      field(:bar, :string)
      field(:buzz, :integer)
    end

    object :quux do
      field(:nested, :foo)
    end
  end

  setup do
    Application.put_env(:absinthe_security, AbsintheSecurity.Phase.MaxAliasesCheck, max_alias_count: 5)
  end

  describe "analysing alias count" do
    test "union runs correctly when less than max alias count" do
      query = """
      query UnionObject {
        aliasA: unionObject {
           ... on Foo {
             aliasB: bar
             buzz
          }
          ... on Quux {
            aliasC: nested {
              buzz
            }
          }
        }
      }
      """

      assert {:ok, result, _} = run_phase(query, operation_name: "UnionObject", variables: %{})
      assert Enum.empty?(result.execution.validation_errors)
    end

    test "union returns an error when there is more alias then the allowed maximum" do
      query = """
      query UnionObject {
        aliasA: unionObject {
           ... on Foo {
             aliasB: bar
             buzz
          }
          ... on Quux {
            aliasC: nested {
              bar
              aliasD: buzz
            }
          }
        }
      }
      """

      assert {:error, result, _} = run_phase(query, operation_name: "UnionObject", variables: %{})

      errors = Enum.map(result.execution.validation_errors, & &1.message)

      assert errors == ["Operation UnionObject has too many aliases: alias count is 6 and maximum is 5"]
    end

    test "fragments runs correctly when less than max alias count" do
      query = """
      query QuuxObject {
        quuxObject {
          aliasA: nested {
            ...FooFields
          }
        }
      }
      fragment FooFields on Foo {
        aliasB: bar
        aliasC: buzz
        aliasD: buzz
      }
      """

      assert {:ok, result, _} = run_phase(query, operation_name: "QuuxObject", variables: %{})
      assert Enum.empty?(result.execution.validation_errors)
    end

    test "fragments returns an error when there is more alias then the allowed maximum" do
      query = """
      query QuuxObject {
        quuxObject {
          aliasA: nested {
            ...FooFields
          }
        }
      }
      fragment FooFields on Foo {
        aliasB: bar
        aliasC: buzz
        aliasD: buzz
        aliasE: buzz
      }
      """

      assert {:error, result, _} = run_phase(query, operation_name: "QuuxObject", variables: %{})

      errors = Enum.map(result.execution.validation_errors, & &1.message)

      assert errors == ["Operation QuuxObject has too many aliases: alias count is 6 and maximum is 5"]
    end
  end
end
