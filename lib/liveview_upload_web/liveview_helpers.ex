defmodule LUWeb.LiveviewHelpers do
  @moduledoc """
  Helpers for LiveView
  """
  def select_options(schemas, field) do
    Enum.map(schemas, fn schema -> {get_in(schema, [Access.key!(field)]), schema.id} end)
  end
end
