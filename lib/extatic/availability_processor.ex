defmodule Extatic.AvailabilityProcessor do
  use GenServer

  def start_link(name) do
     GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def send_availability do
     if availability_reporter, do: availability_reporter.send([])
  end

  def availability_reporter do
    get_config |> Map.get(:reporter)
  end

  def handle_cast(request, state) do
    super(request, state)
  end

  ## Server Callbacks

  def startup_log do
   unless availability_reporter, do: IO.puts "Extatic Availability Reporter not configured!"
  end

  def init(:ok) do
    startup_log
    if availability_reporter, do: Process.send_after(self(), :send, 1 * 1000)
    state = %{config: get_plugin_config} |> set_last_sent
    {:ok, state}
  end

  def set_last_sent(state) do
    state |> Map.put(:last_sent, DateTime.utc_now |>  DateTime.to_unix(:microseconds))
  end

  def queue_processing() do
    queue_processing(configured_interval)
  end

  def queue_processing(0) do end
  def queue_processing(interval) do
    Process.send_after(self(), :send, interval * 1000)
  end


  def handle_info(:send, state) do
    send_availability
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
     get_config Application.get_env(:extatic, :metrics)
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
