defmodule Extatic.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
     children = [
       worker(Extatic.MetricProcessor, [Extatic.MetricProcessor]),
       worker(Extatic.EventProcessor, [Extatic.EventProcessor])
       worker(Extatic.AvailabilityProcessor, [Extatic.AvailabilityProcessor])
     ]

    supervise(children, strategy: :one_for_one)
  end
end
