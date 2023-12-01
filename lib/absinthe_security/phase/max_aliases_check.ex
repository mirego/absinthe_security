defmodule AbsintheSecurity.Phase.MaxAliasesCheck do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Phase

  @default_max_alias_count 50

  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(input, options \\ []) do
    max_alias_count = Keyword.get(options, :max_alias_count, @default_max_alias_count)
    fragments = process_fragments(input, max_alias_count)
    fun = &handle_node(&1, &2, fragments, max_alias_count)

    operation = Blueprint.current_operation(input)
    {operation, {_alias_count, errors}} = Blueprint.postwalk(operation, {0, []}, fun)

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

  defp process_fragments(blueprint, max_alias_count) do
    Enum.reduce(blueprint.fragments, %{}, fn fragment, processed ->
      fun = &handle_node(&1, &2, processed, max_alias_count)
      {fragment, metadata} = Blueprint.postwalk(fragment, {0, []}, fun)
      Map.put(processed, fragment.name, metadata)
    end)
  end

  def handle_node(%Blueprint.Document.Fragment.Spread{name: name} = node, {alias_count, errors}, fragments, _max_alias_count) do
    {fragment_alias_count, fragment_errors} = Map.fetch!(fragments, name)
    {node, {alias_count + fragment_alias_count, errors ++ fragment_errors}}
  end

  def handle_node(%Blueprint.Document.Fragment.Named{selections: fields} = node, {alias_count, errors}, fragments, _max_alias_count) when map_size(fragments) == 0 do
    {node, {alias_count + count_aliases(fields), errors}}
  end

  def handle_node(%Blueprint.Document.Fragment.Named{} = node, acc, _fragments, _max_alias_count) do
    {node, acc}
  end

  def handle_node(%Blueprint.Document.Fragment.Inline{selections: fields} = node, {alias_count, errors}, _fragments, _max_alias_count) do
    {node, {alias_count + count_aliases(fields), errors}}
  end

  def handle_node(%Blueprint.Document.Field{selections: fields} = node, {alias_count, errors}, _fragments, _max_alias_count) do
    child_alias_count = count_aliases(fields)
    {node, {alias_count + child_alias_count, errors}}
  end

  def handle_node(%Blueprint.Document.Operation{selections: fields, source_location: location} = node, {alias_count, errors}, _fragments, max_alias_count) do
    new_alias_count = alias_count + count_aliases(fields)

    if new_alias_count > max_alias_count do
      error = %Phase.Error{
        phase: __MODULE__,
        message: error_message(node, new_alias_count, max_alias_count),
        locations: [location]
      }

      node =
        node
        |> flag_invalid(:too_many_aliases)
        |> put_error(error)

      {node, {new_alias_count, [error | errors]}}
    else
      {node, {new_alias_count, errors}}
    end
  end

  def handle_node(node, acc, _, _) do
    {node, acc}
  end

  defp count_aliases(fields) do
    Enum.reduce(fields, 0, fn
      %{alias: nil}, acc ->
        acc

      _field, acc ->
        acc + 1
    end)
  end

  defp error_message(node, alias_count, max_alias_count) do
    "#{describe_node(node)} has too many aliases: alias count is #{alias_count} and maximum is #{max_alias_count}"
  end

  defp describe_node(%Blueprint.Document.Operation{name: nil}) do
    "Operation"
  end

  defp describe_node(%Blueprint.Document.Operation{name: name}) do
    "Operation #{name}"
  end
end
