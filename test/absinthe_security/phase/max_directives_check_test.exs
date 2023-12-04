defmodule AbsintheSecurity.Phase.MaxDirectivesCheckTest do
  use AbsintheSecurityTest.AbsinthePhaseCase,
    phase: AbsintheSecurity.Phase.MaxDirectivesCheck,
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

  describe "analysing directive count" do
    test "union runs correctly when less than max directive count" do
      query = """
      query UnionObject {
        unionObject {
           ... on Foo {
             bar @skip(if: true)
             buzz @include(if: true)
          }
          ... on Quux {
            nested {
              buzz
              bar @skip(if: false)
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
        unionObject {
           ... on Foo {
             bar @skip(if: true)
             buzz @include(if: true)
          }
          ... on Quux {
            nested {
              aliasA: buzz
              aliasB: buzz @skip(if: false)
              bar @skip(if: false)
            }
          }
        }
      }
      """

      assert {:error, result, _} = run_phase(query, operation_name: "UnionObject", variables: %{})

      errors = Enum.map(result.execution.validation_errors, & &1.message)

      assert errors == ["Operation UnionObject has too many directives: directive count is 4 and maximum is 3"]
    end

    test "fragments runs correctly when less than max alias count" do
      query = """
      query QuuxObject {
        quuxObject {
          nested @skip(if: false) {
            ...FooFields
          }
        }
      }
      fragment FooFields on Foo {
        bar @include(if: false)
        buzz @include(if: true)
        buzz
      }
      """

      assert {:ok, result, _} = run_phase(query, operation_name: "QuuxObject", variables: %{})
      assert Enum.empty?(result.execution.validation_errors)
    end

    test "fragments returns an error when there is more alias then the allowed maximum" do
      query = """
      query QuuxObject {
        quuxObject {
          nested @skip(if: false) {
            ...FooFields
          }
        }
      }
      fragment FooFields on Foo {
        bar @include(if: false)
        buzz @include(if: true)
        buzz @skip(if: false)
      }
      """

      assert {:error, result, _} = run_phase(query, operation_name: "QuuxObject", variables: %{})

      errors = Enum.map(result.execution.validation_errors, & &1.message)

      assert errors == ["Operation QuuxObject has too many directives: directive count is 4 and maximum is 3"]
    end
  end
end
