defmodule AbsintheSecurityTest.AbsinthePhaseCase do
  @moduledoc false

  alias Absinthe.Pipeline

  defmacro __using__(opts) do
    phase = Keyword.fetch!(opts, :phase)
    schema = Keyword.fetch!(opts, :schema)

    quote do
      use ExUnit.Case, unquote(opts)

      @doc """
      Execute the pipeline up to and through a phase.
      """

      @spec run_phase(String.t(), Keyword.t()) :: Absinthe.Phase.result_t()
      def run_phase(query, options) do
        options = Keyword.put(options, :jump_phases, false)

        pipeline = pipeline(unquote(schema), options)
        Absinthe.Pipeline.run(query, Absinthe.Pipeline.upto(pipeline, unquote(phase)))
      end

      defp pipeline(schema, options) do
        options =
          Keyword.merge(options,
            max_alias_count: 5,
            max_directive_count: 3,
            max_depth_count: 4
          )

        unquote(schema)
        |> Pipeline.for_document(options)
        |> Pipeline.insert_after(
          Absinthe.Phase.Document.Complexity.Result,
          [
            {AbsintheSecurity.Phase.MaxAliasesCheck, options},
            {AbsintheSecurity.Phase.MaxDepthCheck, options},
            {AbsintheSecurity.Phase.MaxDirectivesCheck, options}
          ]
        )
      end
    end
  end
end
