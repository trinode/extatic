defmodule Extatic.Logger do
  use GenEvent
  alias Extatic.Models.LogEntry

  def init({__MODULE__, name}) do
    startup_log
    {:ok, %{config: get_plugin_config}}
  end

  def handle_event(data = {level, _grp_lead, {Logger, msg, ts, mdata}}, state = %{config: %{metadata: metadata, level: min_level}}) do
    if log_event?(level, min_level) && is_list(msg)do
      entry = %LogEntry{
        level: level,
        message: stringify(msg),
        timestamp: timestamp(ts),
        metadata: Enum.into(mdata, metadata) |> Map.delete(:pid)
      }

      send_log(entry, state)
    end

    {:ok, state}
  end

  defp stringify(str) when is_binary(str), do: str
  defp stringify(lst) when is_list(lst), do: IO.iodata_to_binary(lst)
  defp stringify(_), do: ""

  def startup_log do
    unless log_reporter, do: IO.puts "Extatic Log Reporter not configured!"
  end

  def send_log(item, config) do
    if log_reporter, do: log_reporter.send(item, config)
  end

  def log_reporter do
    get_config |> Map.get(:reporter)
  end

  defp format({level, _, {_, msg, ts, _}}) do
    %{
      time: timestamp(ts),
      level: level,
      message: msg |> to_string
    }
  end

  def log_event?(level, min_level) do
    is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt
  end

  defp timestamp({{yr, mth, day},{hr, min, sec, ms}}) do
    with {:ok, date_time} <- NaiveDateTime.new(yr, mth, day, hr, min, sec, ms),
    do:  date_time |> NaiveDateTime.to_iso8601
  end

  def get_config do
     get_config Application.get_env(:extatic, :logs)
  end

  def get_config(config = %{}), do: config
  def get_config(nil) do
    %{}
  end

  def get_plugin_config do
    get_plugin_config(Map.get(get_config,:config))
  end
  def get_plugin_config(config = %{}), do: config
  def get_plugin_config(nil) do
    %{}
  end
end
