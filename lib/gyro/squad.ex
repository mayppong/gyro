defmodule Gyro.Squad do
  use GenServer
  alias Gyro.Spinner
  alias Gyro.Squad
  alias Phoenix.Socket

  defstruct name: nil, formed_at: :calendar.universal_time(), score: 0, members: []
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
        :timer.send_interval(@timer, "spin")
        {:ok, squad_pid}
      {:error, {:already_started, squad_pid}} ->
        {:ok, squad_pid}
      error -> error
    end
  end

  def introspect(socket) do
    socket.assigns[:squad_pid]
    |> GenServer.call(:introspect)
  end

  def start_link(state, name) do
    GenServer.start_link(__MODULE__, state, name: {:global, name})
  end

  def handle_call({:enlist, spinner_pid}, _from, state) do
    IO.inspect spinner_pid
    state = Map.put(state, :members, [spinner_pid | state.members])
    {:reply, state, state}
  end

  def handle_call(:introspect, _from, state) do
    response = Map.delete(state, :formed_at)
    {:reply, response, state}
  end

  def handle_call({:update, key, value}, _from, state) do
    {:reply, _from, Map.put(state, key, value)}
  end

  def handle_info("spin", state) do
    score = Enum.reduce(state.members, 0, fn(spinner_pid, acc) ->
      spinner = GenServer.call(spinner_pid, :introspect)
      acc + spinner.score
    end)
    {:noreply, Map.put(state, :score, score)}
  end


end
