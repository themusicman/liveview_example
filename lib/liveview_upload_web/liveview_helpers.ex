defmodule LUWeb.LiveviewHelpers do
  def select_options(schemas, field) do
    Enum.map(schemas, fn schema -> {get_in(schema, [Access.key!(field)]), schema.id} end)
  end
end
