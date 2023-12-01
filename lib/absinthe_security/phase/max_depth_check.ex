defmodule AbsintheSecurity.Phase.MaxDepthCheck do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Phase

  @default_max_depth_count 20

  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, options \\ []) do
    fragments = process_fragments(input)
    operation = Blueprint.current_operation(input)
    {operation, errors} = maybe_add_operation_error(operation, fragments, options)

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

  defp maybe_add_operation_error(%{source_location: source_location} = operation, fragments, options) do
    max_depth_count = Keyword.get(options, :max_depth_count, @default_max_depth_count)
    operation_depth = node_depth(operation, fragments)

    if operation_depth > max_depth_count do
      error = %Phase.Error{
        phase: __MODULE__,
        message: error_message(operation, operation_depth, max_depth_count),
        locations: [source_location]
      }

      operation =
        operation
        |> flag_invalid(:too_many_directives)
        |> put_error(error)

      {operation, [error]}
    else
      {operation, []}
    end
  end

  defp process_fragments(blueprint) do
    Enum.reduce(blueprint.fragments, %{}, fn fragment, processed ->
      fragment_depth = node_depth(fragment, processed)
      Map.put(processed, fragment.name, fragment_depth)
    end)
  end

  defp node_depth(node, fragments, current_depth \\ 0)

  defp node_depth(%Blueprint.Document.Fragment.Spread{name: name}, fragments, current_depth) do
    fragment_depth = Map.fetch!(fragments, name)
    current_depth + fragment_depth
  end

  defp node_depth(%{selections: []}, _fragments, current_depth), do: current_depth

  defp node_depth(%{selections: selections}, fragments, current_depth) do
    selections
    |> Enum.map(fn selection ->
      new_current_depth = if fragment_definition?(selection), do: current_depth, else: current_depth + 1

      node_depth(selection, fragments, new_current_depth)
    end)
    |> Enum.max()
  end

  defp error_message(node, query_depth, max_depth_count) do
    "#{describe_node(node)} is too deep: depth is #{query_depth} and maximum is #{max_depth_count}"
  end

  defp describe_node(%Blueprint.Document.Operation{name: nil}) do
    "Operation"
  end

  defp describe_node(%Blueprint.Document.Operation{name: name}) do
    "Operation #{name}"
  end

  defp fragment_definition?(%Blueprint.Document.Fragment.Inline{}), do: true
  defp fragment_definition?(%Blueprint.Document.Fragment.Named{}), do: true
  defp fragment_definition?(%Blueprint.Document.Fragment.Spread{}), do: true
  defp fragment_definition?(_node), do: false
end
