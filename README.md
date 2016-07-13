# Extatic

** WARNING **
 * There are no tests (yet)
 * The code is a mess (for now)
 * Use at your own risk (always)

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

## Configuration

With extatic_datadog

```
 config :extatic, :config,
 metric_reporter: Extatic.Reporters.Metrics.Datadog,
 metric_config: %{
   url: "https://app.datadoghq.com/api/v1/series",
   api_key: "nope",
   host: "www.example.com"
   },
 event_reporter: Extatic.Reporters.Events.Datadog,
 event_config: %{
   url: "https://app.datadoghq.com/api/v1/events",
   api_key: "nope",
   host: "www.example.com"
 }
```
or (with extatic_console)

```
 config :extatic, :config,
 metric_reporter: Extatic.Reporters.Metrics.Console,
 metric_config: %{},
 event_reporter: Extatic.Reporters.Events.Console,
 event_config: %{}
```

or a combination.

## Providers
[Extatic Console](https://github.com/trinode/extatic_console)

Outputs metrics and errors to the console (it's not pretty but helps when implementing monitoring in development

[Extatic Datadog](https://github.com/trinode/extatic_datadog)

Send metrics and errors to datadog
