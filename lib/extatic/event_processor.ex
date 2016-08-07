defmodule Extatic.EventProcessor do
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


  def push_events(state) do
    snapshot = state
    state = reset_events(state)
    send_events(snapshot)
    state
  end

  def send_events([]), do: nil

  def send_events(events) do
    if event_reporter, do: event_reporter.send(events)
  end

  def event_reporter do
    get_config |> Map.get(:reporter)
  end

  def reset_events(state) do
    state |> Map.put(:events, [])
  end

  def set_last_sent(state) do
    state |> Map.put(:last_sent, DateTime.utc_now |>  DateTime.to_unix(:microseconds))
  end

  def handle_cast({:record_event, %{type: type, title: title, content: content}}, state) do
    {_old_value, state} = Map.get_and_update(state, :events, fn current_value ->

    new_event = %Extatic.Models.Event{type: type, title: title, content: content}

    {current_value, current_value ++ [new_event]}
    end)

    {:noreply, state}
  end

  def handle_cast(request, state) do
    super(request, state)
  end

  ## Server Callbacks

  def startup_log do
     unless event_reporter, do: IO.puts "Extatic Event Reporter not configured!"
  end

  def init(:ok) do
    startup_log
    if event_reporter, do: queue_processing(1)
    state = %{events: [], config: get_plugin_config} |> set_last_sent
    {:ok, state}
  end

  def queue_processing() do
    queue_processing(configured_interval)
  end

  def queue_processing(0) do end
  def queue_processing(interval) do
    Process.send_after(self(), :send, interval * 1000)
  end

  def handle_info(:send, state) do
    state = push_events(state)
    queue_processing
    {:noreply, state}
  end

  def configured_interval do
    configured_interval(Map.get(get_config,:interval))
  end
  def configured_interval(nil) do
    %{}
  end
  def configured_interval(interval), do: interval

  def get_config do
     get_config Application.get_env(:extatic, :events)
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
