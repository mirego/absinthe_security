defmodule AbsintheSecurityTest.AbsinthePhaseCase do
  @moduledoc false

  alias Absinthe.Pipeline

  defmacro __using__(opts) do
    phase = Keyword.fetch!(opts, :phase)
    schema = Keyword.fetch!(opts, :schema)

    quote do
      use ExUnit.Case, unquote(opts)

      alias AbsintheSecurity.Pipeline

      @doc """
      Execute the pipeline up to and through a phase.
      """

      @spec run_phase(String.t(), Keyword.t()) :: Absinthe.Phase.result_t()
      def run_phase(query, options) do
        options = Keyword.put_new(options, :jump_phases, false)

        pipeline = pipeline(unquote(schema), options)
        Absinthe.Pipeline.run(query, Absinthe.Pipeline.upto(pipeline, unquote(phase)))
      end

      defp pipeline(schema, options) do
        unquote(schema)
        |> Pipeline.for_document(options)
        |> Absinthe.Pipeline.insert_after(
          Absinthe.Phase.Document.Complexity.Result,
          [
            AbsintheSecurity.Phase.IntrospectionCheck,
            AbsintheSecurity.Phase.MaxAliasesCheck,
            AbsintheSecurity.Phase.MaxDepthCheck,
            AbsintheSecurity.Phase.MaxDirectivesCheck
          ]
        )
        |> Absinthe.Pipeline.insert_after(Absinthe.Phase.Document.Result, AbsintheSecurity.Phase.DisableFieldSuggestions)
      end
    end
  end
end
