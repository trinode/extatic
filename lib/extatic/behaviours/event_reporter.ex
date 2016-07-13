defmodule Extatic.Behaviours.EventReporter do
  @callback send(List.t) :: any
end
