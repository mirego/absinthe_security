defmodule AbsintheSecurity.Phase.MaxDepthCheckTest do
  use AbsintheSecurityTest.AbsinthePhaseCase,
    phase: AbsintheSecurity.Phase.MaxDepthCheck,
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
      field(:nested_quux, :quux)
    end
  end

  setup do
    Application.put_env(:absinthe_security, AbsintheSecurity.Phase.MaxDepthCheck, max_depth_count: 4)
  end

  describe "analysing depth count" do
    test "union runs correctly when less than max depth count" do
      query = """
      query UnionObject {
        unionObject {
           ... on Foo {
             bar
             buzz
          }
          ... on Quux {
            nested {
              buzz
              bar
            }
            nestedQuux {
              nested {
                bar
              }
            }
          }
        }
      }
      """

      assert {:ok, result, _} = run_phase(query, operation_name: "UnionObject", variables: %{})
      assert Enum.empty?(result.execution.validation_errors)
    end

    test "union returns an error when there is more depth then the allowed maximum" do
      query = """
      query UnionObject {
        unionObject {
           ... on Foo {
             bar
             buzz
          }
          ... on Quux {
            nested {
              buzz
              bar
            }
            nestedQuux {
              nested {
                bar
              }
              nestedQuux {
                nested {
                  bar
                }
              }
            }
          }
        }
      }
      """

      assert {:error, result, _} = run_phase(query, operation_name: "UnionObject", variables: %{})

      errors = Enum.map(result.execution.validation_errors, & &1.message)

      assert errors == ["Operation UnionObject is too deep: depth is 5 and maximum is 4"]
    end

    test "fragments runs correctly when less than max depth count" do
      query = """
      query QuuxObject {
        quuxObject {
          ...QuuxFields
        }
      }
      fragment FooFields on Foo {
        bar
        buzz
      }
      fragment QuuxFields on Quux {
        nested {
          bar
        }
        nestedQuux {
          nested {
            ...FooFields
          }
        }
      }
      """

      assert {:ok, result, _} = run_phase(query, operation_name: "QuuxObject", variables: %{})
      assert Enum.empty?(result.execution.validation_errors)
    end

    test "fragments returns an error when there is more alias then the allowed maximum" do
      query = """
      query QuuxObject {
        quuxObject {
          ...QuuxFields
        }
      }
      fragment FooFields on Foo {
        bar
        buzz
      }
      fragment QuuxFields on Quux {
        nested {
          bar
        }
        nestedQuux {
          nested {
            ...FooFields
          }
          nestedQuux {
            nested {
              ...FooFields
            }
          }
        }
      }
      """

      assert {:error, result, _} = run_phase(query, operation_name: "QuuxObject", variables: %{})

      errors = Enum.map(result.execution.validation_errors, & &1.message)

      assert errors == ["Operation QuuxObject is too deep: depth is 5 and maximum is 4"]
    end
  end
end
