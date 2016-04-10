defmodule Gyro.Squad do
  use GenServer

  alias Gyro.Squad
  alias Phoenix.Socket

  defstruct name: nil, score: 0, latest: [],
    formed_at: :calendar.universal_time(), members: []

  @timer 5000

  @doc """
  A convenient method for starting a GenServer for a squad of specified name.
  If starts successfully, we pass a tuple of `:ok` status and the pid back,
  `{:ok, squad_pid}`. The process will also begin sending message "spin" to
  itself in an interval as specified by the module timer variable as well.
  If there is already a squad with that name, we pass the pid of that squad
  back as if we successfully started the squad. Otherwise, pass the `:error`
  status and reason back.
  """
  def start(name) do
    case start_link(%Squad{name: name}, name) do
      {:ok, squad_pid} ->
        :timer.send_interval(@timer, squad_pid, :spin)
        {:ok, squad_pid}
      {:error, {:already_started, squad_pid}} ->
        {:ok, squad_pid}
      error -> error
    end
  end

  @doc """
  Add the spinner from the given socket to a squad of a given name. If the
  squad doesn't already exist, also start it.
  """
  def enlist(name, socket) do
    case start(name) do
      {:ok, squad_pid} ->
        GenServer.call(squad_pid, {:enlist, socket.assigns[:spinner_pid]})
        {:ok, Socket.assign(socket, :squad_pid, squad_pid)}
      error -> error
    end
  end

  end

  @doc """
  Inspect the current state of the Squad assigned to the given socket
  """
  def introspect(socket) do
    state = socket.assigns[:squad_pid]
    |> GenServer.call(:introspect)
    Socket.assign(socket, :squad, state)
  end

  @doc """
  TODO: DEPRECATE
  Stop the squad GenServer assigned to the given socket with a given reason
  """
  def stop(socket, reason) do
    socket.assigns[:squad_pid]
    |> GenServer.stop(reason)

    socket
    |> Socket.assign(:squad, nil)
    |> Socket.assign(:squad_pid, nil)
  end

  @doc """
  Start a new GenServer process for a squad.
  The GenServer will be registered in the global registry with the name. This
  means the squad name is unique and can be referenced by name from anywhere
  in the system without the process id.
  """
  def start_link(state, name) do
    GenServer.start_link(__MODULE__, state, name: {:global, name})
  end

  @doc """
  Handle adding a new spinner to the squad.
  The new spinner is stored in the member list as a tuple with the first
  value being the spinner id and the second value be the current known state
  of the spinner.
  """
  def handle_call({:enlist, spinner_pid}, _from, state) do
    member = {spinner_pid, inspect_spinner(spinner_pid)}
    state = Map.put(state, :members, [member | state.members])
    {:reply, state, state}
  end

  @doc """
  Handle a call to get the current state stored in the process.
  """
  def handle_call(:introspect, _from, state) do
    {:reply, state, state}
  end

  @doc """
  Handle updating a key in the current state.
  """
  def handle_call({:update, key, value}, from, state) do
    state = Map.put(state, key, value)
    {:reply, state, state}
  end

  @doc """
  Handle `spinning` which is where we update the current state of the squad
  at a set interval.
  """
  def handle_info(:spin, state) do
    state = state
    |> update_members
    |> update_score
    |> update_latest

    {:noreply, state}
  end

  # Private method for getting the current state of a spinner for a given
  # spinner pid.
  defp inspect_spinner(spinner_pid) do
    GenServer.call(spinner_pid, :introspect)
  end

  # Private method for iterating through members in the squad state and
  # update each member current state.
  defp update_members(state) do
    members = Enum.map(state.members, fn({spinner_pid, _}) ->
      {spinner_pid, inspect_spinner(spinner_pid)}
    end)
    Map.put(state, :members, members)
  end

  # Private method for iterating through all members and summing up their
  # score.
  defp update_score(state) do
    score = state.members
    |> Enum.reduce(0, fn({_, spinner}, acc) ->
      acc + spinner.score
    end)
    Map.put(state, :score, score)
  end

  # Private method for finding the newest spinners in the squad.
  # This is done by iterating through members, sort them by their connected
  # time, and take only the first 10 from the list.
  defp update_latest(state) do
    latest = state.members
    |> Enum.sort(fn({_, spinner_1}, {_, spinner_2}) ->
      spinner_1.connected_at < spinner_2. connected_at
    end)
    |> Enum.take(10)
    |> minify

    Map.put(state, :latest, latest)
  end

  # Private method for cleaning up spinner state before we add them to the
  # list. There are some data in each spinner where we might not care for.
  # This is a good place where we can clean them up and store just the data
  # we need.
  defp minify(members) do
    members
    |> Enum.map(fn({_spinner, spinner}) ->
      spinner
      |> Map.delete(:connected_at)
    end)
  end
end
