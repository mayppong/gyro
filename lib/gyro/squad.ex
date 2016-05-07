defmodule Gyro.Squad do
  use GenServer

  alias Gyro.Spinner
  alias Gyro.Squad

  defstruct name: nil, spm: 0, score: 0, latest: [],
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
  def form(name) do
    case exists?(name) do
      true ->
        {:ok, {:global, name}}
      false ->
        import Supervisor.Spec

        child = worker(Squad, [%Squad{name: name}, {:global, name}], [name: {:global, name}])
        case Supervisor.start_child(Gyro.Supervisor, child) do
          {:ok, squad_pid} ->
            {:ok, squad_pid}
          {:error, {:already_started, squad_pid}} ->
            {:ok, squad_pid}
          {:error, {{:already_started, squad_pid}, _}} ->
            {:ok, squad_pid}
          error ->
            error
        end
    end
  end

  @doc """
  Add the given spinner to a squad of a given name. If the squad doesn't
  already exist, also start it.
  """
  def enlist(name, spinner_pid) do
    case form(name) do
      {:ok, squad_pid} ->
        GenServer.call(squad_pid, {:enlist, spinner_pid})
        {:ok, squad_pid}
      error -> error
    end
  end

  @doc """
  Check if squad is still alive.
  """
  def exists?(name) when is_bitstring(name), do: exists?({:global, name})
  def exists?(name) do
    nil != GenServer.whereis(name)
  end

  @doc """
  Remove the spinner from the given squad.
  """
  def delist(squad_pid, spinner_pid) do
    GenServer.call(squad_pid, {:delist, spinner_pid})
  end

  @doc """
  Inspect the current state of the given squad.
  """
  def introspect(squad_pid) do
    GenServer.call(squad_pid, :introspect)
  end

  @doc """
  Stop the given squad GenServer.
  """
  def disband(squad_pid, reason \\ :normal) do
    GenServer.stop(squad_pid, reason)
  end

  @doc """
  Start a new GenServer process for a squad.
  The GenServer will be registered in the global registry with the name. This
  means the squad name is unique and can be referenced by name from anywhere
  in the system without the process id.
  """
  def start_link(_, :arena), do: {:error, %{reason: "Reserved name"}}
  def start_link(state, name) do
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @doc """
  Once the GenServer is started successfully, the init function is invoked.
  For now, we just need to tell it to start spinning.
  """
  def init(state) do
    :timer.send_interval(@timer, self, :spin)
    {:ok, state}
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
  Handle a member leaving the squad.
  We need to remove the member from the member list. The ideal situation
  would be to find the member from the list by map. However, since we're
  using the spinner pid as "key"-ish right now, we can't look up the member
  listing map by key right now.
  """
  def handle_call({:delist, quitter_pid}, _from, state) do
    members = state.members
    |> Enum.filter(fn({spinner_pid, _}) ->
      spinner_pid != quitter_pid
    end)

    state = Map.put(state, :members, members)
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
  def handle_call({:update, key, value}, _, state) do
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
    case Spinner.exists?(spinner_pid) do
      false -> %{score: 0, spm: 0}
      true -> Spinner.introspect(spinner_pid)
    end
  end

  # Private method for iterating through members in the squad state and
  # update each member current state.
  # TODO: check if member exists first too
  defp update_members(state) do
    members = Enum.map(state.members, fn({spinner_pid, _}) ->
      {spinner_pid, inspect_spinner(spinner_pid)}
    end)
    Map.put(state, :members, members)
  end

  # Private method for iterating through all members and summing up their
  # score.
  defp update_score(state) do
    {score, spm} = state.members
    |> Enum.reduce({0, 0}, fn({_, spinner}, {score, spm}) ->
      {score + spinner.score, spm + spinner.spm}
    end)

    state
    |> Map.put(:score, score)
    |> Map.put(:spm, spm)
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
  # TODO: once we can JSONify this, we won't need this method any more
  defp minify(members) do
    members
    |> Enum.map(fn({_spinner, spinner}) ->
      spinner
      |> Map.delete(:connected_at)
    end)
  end
end
