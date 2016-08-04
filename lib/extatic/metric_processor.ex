defmodule Extatic.MetricProcessor do
  use GenServer
  alias Extatic.Models.Metric

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
    items |> Enum.map(fn v ->
            %Metric{name: v.name, value: average_for_list(v.value)}
    end)
  end

  def average_for_list(items) do
    record_count = Enum.count(items)
    total = Enum.sum(items)
    cond do
      record_count > 0 -> total / record_count
      true -> 0
    end
  end

  def per_time(stats, time) do
    stats |> Enum.map(fn m ->
            %Metric{name: m.name, value: m.value * 1_000_000 / time}
    end)
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

  def send_stats([]), do: nil

  def send_stats(stats) do
     if metric_reporter, do: metric_reporter.send(stats)
  end

  def metric_reporter do
    Application.get_env(:extatic, :metrics) |> Map.get(:reporter)
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
    {:noreply, state}
  end

  def handle_cast({:set_gauge, %{gauge: gauge_name, value: value}}, state) do
    guages = state.gauges

    gauges = Map.put(guages, gauge_name, value)

    state = Map.put(state, :gauges, gauges)

    {:noreply, state}
  end


  def handle_cast({:record_timing, %{timing_name: name, value: value}}, state) do
    timings = state.timings

    {_old_value, timings} = Map.get_and_update(timings, name, fn current_value ->
      new_list = case current_value do
        nil -> [value]
        _ -> current_value ++ [value]
      end
      {current_value, new_list}
    end)

    state = Map.put(state, :timings, timings)

    {:noreply, state}
  end

  def handle_cast(request, state) do
    super(request, state)
  end

  ## Server Callbacks

  def startup_log do
     unless metric_reporter, do: IO.puts "Extatic Metric Reporter not configured!"
  end

  def init(:ok) do
    IO.puts "init"
    startup_log
    Process.send_after(self(), :send, 1 * 1000)
    state = %{counters: %{}, gauges: %{}, timings: %{}, config: get_plugin_config} |> set_last_sent
    {:ok, state}
  end

  def handle_info(:send, state) do
    state = push_stats(state)
    queue_processing()
    IO.puts "send"
    {:noreply, state}
  end

  def queue_processing() do
    queue_processing(configured_interval)
  end

  def queue_processing(0) do end
  def queue_processing(interval) do
    Process.send_after(self(), :send, interval * 1000)
  end

  def configured_interval do
    configured_interval(Map.get(get_config,:interval))
  end
  def configured_interval(nil) do
    %{}
  end
  def configured_interval(interval), do: interval

  def get_config do
     Application.get_env(:extatic, :metrics)
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
