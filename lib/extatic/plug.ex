defmodule Extatic.ExtaticPlug do
  @behaviour Plug
  import Plug.Conn, only: [register_before_send: 2]

  def init(opts), do: opts

  def call(conn, _config) do
    before_time = DateTime.utc_now |>  DateTime.to_unix(:microseconds)

    register_before_send conn, fn conn ->
      after_time = DateTime.utc_now |>  DateTime.to_unix(:microseconds)
      diff       = after_time - before_time
      
      Extatic.record_timing(:response_time, diff)

      conn
    end
  end
end
