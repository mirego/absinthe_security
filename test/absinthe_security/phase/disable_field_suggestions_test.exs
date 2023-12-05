defmodule AbsintheSecurity.Phase.DisableFieldSuggestionsTest do
  use AbsintheSecurityTest.AbsinthePhaseCase,
    phase: AbsintheSecurity.Phase.DisableFieldSuggestions,
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

  describe "field suggestions" do
    test "are returned when it's enabled" do
      query = """
      query FooObject {
        fooObject {
          buz
        }
      }
      """

      assert {:ok, result, _} = run_phase(query, operation_name: "FooObject", variables: %{}, enable_field_suggestions: true, jump_phases: true)

      [error] = result.result.errors
      assert error.message === "Cannot query field \"buz\" on type \"Foo\". Did you mean \"buzz\"?"
    end

    test "are not returned when it's disabled" do
      query = """
      query FooObject {
        fooObject {
          buz
        }
      }
      """

      assert {:ok, result, _} = run_phase(query, operation_name: "FooObject", variables: %{}, enable_field_suggestions: false, jump_phases: true)

      [error] = result.result.errors
      assert error.message === "Cannot query field \"buz\" on type \"Foo\"."
    end
  end
end
