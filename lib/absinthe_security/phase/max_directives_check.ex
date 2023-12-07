defmodule AbsintheSecurity.Phase.MaxDirectivesCheck do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Phase

  @default_max_directive_count 20

  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, options \\ []) do
    max_directive_count = Application.get_env(:absinthe_security, :max_directive_count, @default_max_directive_count)
    fragments = process_fragments(input, max_directive_count)
    fun = &handle_node(&1, &2, fragments, max_directive_count)

    operation = Blueprint.current_operation(input)
    {operation, {_directive_count, errors}} = Blueprint.postwalk(operation, {0, []}, fun)

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

  defp process_fragments(blueprint, max_directive_count) do
    Enum.reduce(blueprint.fragments, %{}, fn fragment, processed ->
      fun = &handle_node(&1, &2, processed, max_directive_count)
      {fragment, metadata} = Blueprint.postwalk(fragment, {0, []}, fun)
      Map.put(processed, fragment.name, metadata)
    end)
  end

  def handle_node(%Blueprint.Document.Fragment.Spread{name: name} = node, {directive_count, errors}, fragments, _max_directives_count) do
    {fragment_directive_count, fragment_errors} = Map.fetch!(fragments, name)
    {node, {directive_count + fragment_directive_count, errors ++ fragment_errors}}
  end

  def handle_node(%Blueprint.Document.Fragment.Named{selections: fields} = node, {directive_count, errors}, fragments, _max_directives_count) when map_size(fragments) == 0 do
    {node, {directive_count + count_directives(fields), errors}}
  end

  def handle_node(%Blueprint.Document.Fragment.Named{} = node, acc, _fragments, _max_directive_count) do
    {node, acc}
  end

  def handle_node(%Blueprint.Document.Fragment.Inline{selections: fields} = node, {directive_count, errors}, _fragments, _max_directive_count) do
    {node, {directive_count + count_directives(fields), errors}}
  end

  def handle_node(%Blueprint.Document.Field{selections: fields} = node, {directive_count, errors}, _fragments, _max_directive_count) do
    child_directive_count = count_directives(fields)
    {node, {directive_count + child_directive_count, errors}}
  end

  def handle_node(%Blueprint.Document.Operation{selections: fields, source_location: location} = node, {directive_count, errors}, _fragments, max_directive_count) do
    new_directive_count = directive_count + count_directives(fields)

    if new_directive_count > max_directive_count do
      error = %Phase.Error{
        phase: __MODULE__,
        message: error_message(node, new_directive_count, max_directive_count),
        locations: [location]
      }

      node =
        node
        |> flag_invalid(:too_many_directives)
        |> put_error(error)

      {node, {new_directive_count, [error | errors]}}
    else
      {node, {new_directive_count, errors}}
    end
  end

  def handle_node(node, acc, _, _) do
    {node, acc}
  end

  defp count_directives(fields) do
    Enum.reduce(fields, 0, fn
      %{directives: []}, acc ->
        acc

      _field, acc ->
        acc + 1
    end)
  end

  defp error_message(node, directive_count, max_directive_count) do
    "#{describe_node(node)} has too many directives: directive count is #{directive_count} and maximum is #{max_directive_count}"
  end

  defp describe_node(%Blueprint.Document.Operation{name: nil}) do
    "Operation"
  end

  defp describe_node(%Blueprint.Document.Operation{name: name}) do
    "Operation #{name}"
  end
end
