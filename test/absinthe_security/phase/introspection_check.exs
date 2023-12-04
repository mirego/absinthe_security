defmodule AbsintheSecurity.Phase.IntrospectionCheckTest do
  use AbsintheSecurityTest.AbsinthePhaseCase,
    phase: AbsintheSecurity.Phase.IntrospectionCheck,
    schema: __MODULE__.Schema,
    async: true

  defmodule Schema do
    @moduledoc false
    use Absinthe.Schema

    query do
      field :foo_object, :foo do
      end
    end

    object :foo do
      field(:bar, :string)
      field(:buzz, :integer)
    end
  end

  describe "introspection check" do
    test "returns no errors when it's enabled and we query __schema" do
      query = """
      query Schema {
        __schema {
          types {
            name
          }
        }
      }
      """

      assert {:ok, result, _} = run_phase(query, operation_name: "Schema", variables: %{}, enable_introspection: true)
      assert Enum.empty?(result.execution.validation_errors)
    end

    test "returns no errors when it's enabled and we do not query any introspection field" do
      query = """
      query FooObject {
        fooObject {
          bar
        }
      }
      """

      assert {:ok, result, _} = run_phase(query, operation_name: "FooObject", variables: %{}, enable_introspection: true)
      assert Enum.empty?(result.execution.validation_errors)
    end

    test "returns no errors when it's disabled and we do not query any introspection field" do
      query = """
      query FooObject {
        fooObject {
          bar
        }
      }
      """

      assert {:ok, result, _} = run_phase(query, operation_name: "FooObject", variables: %{}, enable_introspection: false)
      assert Enum.empty?(result.execution.validation_errors)
    end

    test "returns an error when it's disabled and we query an introspection field" do
      query = """
      query Schema {
        __schema {
          types {
            name
          }
        }
      }
      """

      assert {:error, result, _} = run_phase(query, operation_name: "Schema", variables: %{}, enable_introspection: false)

      errors = Enum.map(result.execution.validation_errors, & &1.message)

      assert errors == ["GraphQL introspection is not allowed but the query contained __schema or __type."]
    end

    test "returns an error when it's disabled and querying SCHEMA in uppercase" do
      query = """
      query Schema {
        __SCHEMA {
          types {
            name
          }
        }
      }
      """

      assert {:error, result, _} = run_phase(query, operation_name: "Schema", variables: %{}, enable_introspection: false)

      errors = Enum.map(result.execution.validation_errors, & &1.message)

      assert errors == ["GraphQL introspection is not allowed but the query contained __schema or __type."]
    end
  end
end
