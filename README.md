# Extatic

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `extatic` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:extatic, "~> 0.1.0"}]
    end
    ```

  2. Ensure `extatic` is started before your application:

    ```elixir
    def application do
      [applications: [:extatic]]
    end
    ```

    iex(8)> Process.register(:wee,self)
** (FunctionClauseError) no function clause matching in Process.register/2
    (elixir) lib/process.ex:413: Process.register(:wee, #PID<0.175.0>)
iex(8)> Process.register(self, :wee)
true
iex(9)> Process.send
send/3          send_after/3
iex(9)> Process.send_after(:wee,:go,1000)


```
defmodule MyApp.Periodically do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Process.send_after(self(), :work, 2 * 60 * 60 * 1000) # In 2 hours
    {:ok, state}
  end

  def handle_info(:work, state) do
    # Do the work you desire here

    # Start the timer again
    Process.send_after(self(), :work, 2 * 60 * 60 * 1000) # In 2 hours

    {:noreply, state}
  end
end
```


```

defmodule PlugExometer do
  @behaviour Plug
  import Plug.Conn, only: [register_before_send: 2]
  alias :exometer, as: Exometer

  def init(opts), do: opts

  def call(conn, _config) do
    before_time = :os.timestamp

    register_before_send conn, fn conn ->
      after_time = :os.timestamp
      diff       = :timer.now_diff after_time, before_time

      :ok = Exometer.update [:morgue, :webapp, :resp_time], diff / 1_000
      :ok = Exometer.update [:morgue, :webapp, :resp_count], 1
      conn
    end
  end
end
```

```
defmodule Morgue.Repo do
  use Ecto.Repo, otp_app: :my_awesome_app

  def log(log_entry) do
    :ok = :exometer.update ~w(my_awesome_webapp ecto query_exec_time)a, (log_entry.query_time + log_entry.queue_time || 0) / 1_000
    :ok = :exometer.update ~w(my_awesome_webapp ecto query_queue_time)a, (log_entry.queue_time || 0) / 1_000 # Note: You will have to add this to conf/exometer.exs if you want it
    :ok = :exometer.update ~w(my_awesome_webapp ecto query_count)a, 1

    super log_entry
  end
end
```
