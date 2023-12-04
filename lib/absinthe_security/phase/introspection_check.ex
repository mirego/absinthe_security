defmodule AbsintheSecurity.Phase.IntrospectionCheck do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Phase

  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, options \\ []) do
    if Keyword.get(options, :enable_introspection, false) do
      {:ok, input}
    else
      do_run(input, options)
    end
  end

  defp do_run(input, options) do
    fragments = process_fragments(input)
    fun = &handle_node(&1, &2, fragments)

    operation = Blueprint.current_operation(input)
    {operation, errors} = Blueprint.postwalk(operation, [], fun)

    blueprint = Blueprint.update_current(input, fn _ -> operation end)
    blueprint = put_in(blueprint.execution.validation_errors, errors)

    case {errors, Map.new(options)} do
      {[], _} ->
        {:ok, blueprint}

      {_errors, %{jump_phases: true, result_phase: abort_phase}} ->
        {:jump, blueprint, abort_phase}

      _ ->
        {:error, blueprint}
    end
  end

  defp process_fragments(blueprint) do
    Enum.reduce(blueprint.fragments, %{}, fn fragment, processed ->
      fun = &handle_node(&1, &2, processed)
      {fragment, metadata} = Blueprint.postwalk(fragment, [], fun)
      Map.put(processed, fragment.name, metadata)
    end)
  end

  def handle_node(%Blueprint.Document.Fragment.Spread{name: name} = node, errors, fragments) do
    fragment_errors = Map.fetch!(fragments, name)
    {node, errors ++ fragment_errors}
  end

  def handle_node(%Blueprint.Document.Field{name: name, source_location: location} = node, errors, _fragments) do
    if String.downcase(name) in ~w(__schema __type) do
      error = %Phase.Error{
        phase: __MODULE__,
        message: error_message(),
        locations: [location]
      }

      node =
        node
        |> flag_invalid(:introspection_disabled)
        |> put_error(error)

      {node, [error | errors]}
    else
      {node, errors}
    end
  end

  def handle_node(node, acc, _fragments) do
    {node, acc}
  end

  defp error_message do
    "GraphQL introspection is not allowed but the query contained __schema or __type."
  end
end
