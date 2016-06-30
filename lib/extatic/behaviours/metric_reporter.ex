defmodule Extatic.Behaviours.MetricReporter do
  @callback send(List.t) :: any
end
