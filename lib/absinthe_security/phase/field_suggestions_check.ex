defmodule AbsintheSecurity.Phase.FieldSuggestionsCheck do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Phase

  @spec run(Blueprint.t(), Keyword.t()) :: Phase.result_t()
  def run(blueprint, _options) do
    phase_options = Application.get_env(:absinthe_security, __MODULE__, [])
    enable_field_suggestions = Keyword.get(phase_options, :enable_field_suggestions, false)

    if enable_field_suggestions do
      {:ok, blueprint}
    else
      do_run(blueprint)
    end
  end

  defp do_run(blueprint) do
    result =
      case blueprint.result do
        %{errors: errors} -> %{blueprint.result | errors: remove_field_suggestions(errors)}
        _ -> blueprint.result
      end

    {:ok, %{blueprint | result: result}}
  end

  def remove_field_suggestions(errors) do
    Enum.map(errors, fn error ->
      case Regex.run(~r/ Did you mean.+/, error.message) do
        [match] -> Map.put(error, :message, String.replace(error.message, match, ""))
        _ -> error
      end
    end)
  end
end
