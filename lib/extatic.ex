defmodule Extatic do
  use Application

  def start(_type, _args) do
    Extatic.Supervisor.start_link
  end

  # utility function to time code block

  defmacro time(name, do: block) do
    quote do
      start_at = DateTime.utc_now |> DateTime.to_unix(:microseconds)

      return_value = unquote(block)

      end_at = DateTime.utc_now |> DateTime.to_unix(:microseconds)
      timing = end_at - start_at

      Extatic.record_timing(unquote(name), timing)
      return_value
     end
  end


  ### Increment a counter (eg visit count) (initialising if necessary)

  def increment_counter(counter_name) do
    GenServer.cast(Extatic.MetricProcessor, {:increment_counter, counter_name})
  end

  ### set a guage (eg memory usage) (initialising if necessary)

  def set_guage(gauge_name, value) do
    GenServer.cast(Extatic.MetricProcessor, {:set_gauge, %{gauge: gauge_name, value: value}})
  end

  ### record a timing (eg a single web request, or a background process run time)

  def record_timing(name, value) do
    GenServer.cast(Extatic.MetricProcessor, {:record_timing, %{timing_name: name, value: value}})
  end

  ### record an event of a given type (eg :deployment, :error, :info) at a given level (eg :error, :warning, :info)

  def record_event(type, title, content) do
     GenServer.cast(Extatic.EventProcessor, {:record_event, %{type: type, title: title, content: content}})
  end
end
