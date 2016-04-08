defmodule Gyro.Squad do
  use GenServer

  alias Gyro.Squad
  alias Phoenix.Socket

  defstruct name: nil, score: 0, latest: [],
    formed_at: :calendar.universal_time(), members: []

  @timer 5000

  def enlist(name, socket) do
    case start(name) do
      {:ok, squad_pid} ->
        GenServer.call(squad_pid, {:enlist, socket.assigns[:spinner_pid]})
        {:ok, Socket.assign(socket, :squad_pid, squad_pid)}
      error -> error
    end
  end

  def start(name) do
    case start_link(%Squad{name: name}, name) do
      {:ok, squad_pid} ->
        :timer.send_interval(@timer, squad_pid, "spin")
        {:ok, squad_pid}
      {:error, {:already_started, squad_pid}} ->
        {:ok, squad_pid}
      error -> error
    end
  end

  def introspect(socket) do
    state = socket.assigns[:squad_pid]
    |> GenServer.call(:introspect)
    Socket.assign(socket, :squad, state)
  end

  def stop(socket, reason) do
    socket.assigns[:squad_pid]
    |> GenServer.stop(reason)

    socket
    |> Socket.assign(:squad, nil)
    |> Socket.assign(:squad_pid, nil)
  end

  def start_link(state, name) do
    GenServer.start_link(__MODULE__, state, name: {:global, name})
  end

  def handle_call({:enlist, spinner_pid}, _from, state) do
    member = {spinner_pid, inspect_spinner(spinner_pid)}
    state = Map.put(state, :members, [member | state.members])
    {:reply, state, state}
  end

  def handle_call(:introspect, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:update, key, value}, from, state) do
    {:reply, from, Map.put(state, key, value)}
  end

  def handle_info("spin", state) do
    state = state
    |> update_members
    |> update_score
    |> update_latest

    {:noreply, state}
  end

  defp inspect_spinner(spinner_pid) do
    GenServer.call(spinner_pid, :introspect)
  end

  defp update_members(state) do
    members = Enum.map(state.members, fn({spinner_pid, _}) ->
      {spinner_pid, inspect_spinner(spinner_pid)}
    end)
    Map.put(state, :members, members)
  end

  defp update_score(state) do
    score = state.members
    |> Enum.reduce(0, fn({_, spinner}, acc) ->
      acc + spinner.score
    end)
    Map.put(state, :score, score)
  end

  defp update_latest(state) do
    latest = state.members
    |> Enum.sort(fn({_, spinner_1}, {_, spinner_2}) ->
      spinner_1.connected_at < spinner_2. connected_at
    end)
    |> Enum.take(10)
    |> minify

    Map.put(state, :latest, latest)
  end

  defp minify(members) do
    members
    |> Enum.map(fn({_spinner, spinner}) ->
      spinner
      |> Map.delete(:connected_at)
    end)
  end
end
