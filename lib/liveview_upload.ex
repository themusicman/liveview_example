defmodule LU do
  @moduledoc """
  LU keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def random_string(bytes \\ 10) do
    bytes
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
