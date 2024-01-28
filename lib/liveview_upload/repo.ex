defmodule LU.Repo do
  use Ecto.Repo,
    otp_app: :liveview_upload,
    adapter: Ecto.Adapters.Postgres
end
