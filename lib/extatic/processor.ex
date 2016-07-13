defmodule Extatic.Processor do
  use GenServer
  alias Extatic.Models.Metric
  ## Client API

  @doc """
  Starts the registry.
  """
  def start_link(name) do
     GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def to_list(map) do
    map |> Enum.map(fn {k, v} ->
            %Metric{name: k, value: v}
    end)
  end

  def group_stats(stats, start_at, end_at) do

    counters = stats.counters || %{}
    counters = to_list(counters)
    counters = per_time(counters, end_at - start_at)
    gauges = stats.gauges || %{}
    gauges = to_list(gauges)

    timings = stats.timings || %{}
    timings = to_list(timings)
    timings = average_for_timings(timings)

    counters ++ gauges ++ timings
  end

  def average_for_timings(items) do
    IO.inspect items
    items |> Enum.map(fn v ->
            %Metric{name: v.name, value: average_for_list(v.value)}
    end)
  end

  def average_for_list(items) do
    IO.puts "averaging"
    IO.inspect items
    record_count = Enum.count(items)
    total = Enum.sum(items)
    cond do
      record_count > 0 -> total / record_count
      true -> 0
    end
  end

  def per_time(stats, time) do
    stats |> Enum.map(fn m ->
            %Metric{name: m.name, value: m.value * 1000000 / time}
    end)
  end



  def push_events(state) do
    # rather lose events than send them forever in case of weirdness
    snapshot = state
    state = reset_events(state)
    send_events(snapshot)
    state
  end

  def send_events([]) do
    IO.puts "No events to send, all is normal, yippie!"
  end

  def send_events(events) do
     event_reporter = Application.get_env(:extatic, :config) |> Keyword.get(:event_reporter)
     event_reporter.send(events)
  end

  def reset_events(state) do
    state |> Map.put(:events, [])
  end

  def push_stats(state) do
    snapshot = state
    start_at = state.last_sent
    state = reset_stats(state)
    end_at = state.last_sent

    stat_list =  group_stats(snapshot,start_at, end_at)
    send_stats(stat_list)
    state
  end

  def send_stats([]) do
    IO.puts "No Stats to send"
  end

  def send_stats(stats) do
     metric_reporter = Application.get_env(:extatic, :config) |> Keyword.get(:metric_reporter)
     metric_reporter.send(stats)
  end

  def reset_stats(state) do
    state |> Map.put(:counters, %{})
          |> Map.put(:gauges, %{})
          |> Map.put(:timings, %{})
          |> set_last_sent
  end

  def set_last_sent(state) do
    state |> Map.put(:last_sent, DateTime.utc_now |>  DateTime.to_unix(:microseconds))
  end


  def handle_cast({:increment_counter, counter_name}, state) do
    counters = state.counters

    counters = Map.update(counters, counter_name, 1 , fn current_value  ->
      case current_value do
        nil -> 1
        _ -> current_value + 1
      end
    end)

    state = Map.put(state, :counters, counters)
    IO.inspect state
    {:noreply, state}
  end

  def handle_cast({:set_gauge, %{gauge: gauge_name, value: value}}, state) do
    guages = state.gauges

    gauges = Map.put(guages, gauge_name, value)

    state = Map.put(state, :gauges, gauges)
    IO.inspect state
    {:noreply, state}
  end


  def handle_cast({:record_timing, %{timing_name: name, value: value}}, state) do
    timings = state.timings

    {old_value, timings} = Map.get_and_update(timings, name, fn current_value ->
      IO.puts current_value
      new_list = case current_value do
        nil -> [value]
        _ -> current_value ++ [value]
      end
      {current_value, new_list}
    end)

    state = Map.put(state, :timings, timings)
    IO.inspect state
    {:noreply, state}
  end

  def handle_cast({:record_event, %{type: type, title: title, content: content}}, state) do
    {old_value, state} = Map.get_and_update(state, :events, fn current_value ->

    new_event = %Extatic.Models.Event{type: type, title: title, content: content}

    {current_value, current_value ++ [new_event]}
    end)

    {:noreply, state}
  end

  def handle_cast(request, state) do
    super(request, state)
  end

  ## Server Callbacks

  def init(:ok) do
    Process.send_after(self(), :send, 1 * 1000) # In 2 hours
    state = %{counters: %{}, gauges: %{}, timings: %{}, events: [] } |> set_last_sent
    {:ok, state}
  end

  def handle_info(:send, state) do
    state = push_stats(state)
    state = push_events(state)
    Process.send_after(self(), :send, 10 * 1000)
    IO.puts "Processing...."
    {:noreply, state}
  end

end
