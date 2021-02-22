defmodule Gyro.Arena do
  @moduledoc """
  The `Arena` module is an implmentation of GenServer for tracking all active
  players in the game.
  It also implements public API for working with Arena's GenServer handler
  without needing GenServer module. This allows the user of Arena to depends
  solely on Arena module itself without GenServer module as dependency.

  A data struct is defined for used internally by GenServer as state data, as
  well as a Poison's Encoder for handling how to JSONify the struct.
  """
  use GenServer

  alias Gyro.Arena.Spinnable
  alias Gyro.Scoreboard

  @derive {Jason.Encoder, except: [:members]}
  defstruct members: %{}, score: 0, spm: 0, size: 0, scoreboard: %Scoreboard{}

  @type on_start :: {:ok, pid} | :ignore | {:error, {:already_started, pid} | term}

  @spinners_pid {:global, :spinners}
  @squads_pid {:global, :squads}
  @timer 1000

  @doc """
  A public API for adding the given spinner pid to the spinner roster.

  Returns `:ok`
  """
  @spec enlist(:spinners, pid) :: :ok
  def enlist(:spinners, spinnable_pid) do
    GenServer.cast(@spinners_pid, {:enlist, spinnable_pid})
  end

  @doc """
  A public API for adding the given squad pid to the squad roster.

  Returns `:ok`
  """
  @spec enlist(:squads, pid) :: :ok
  def enlist(:squads, spinnable_pid) do
    GenServer.cast(@squads_pid, {:enlist, spinnable_pid})
  end

  @doc """
  A public API for removing the given spinner pid from the spinner roster.

  Returns `:ok`
  """
  @spec delist(:spiners, pid) :: :ok
  def delist(:spinners, spinnable_pid) do
    GenServer.cast(@spinners_pid, {:delist, spinnable_pid})
  end

  @doc """
  A public API for removing the given squad pid from the squad roster.

  Returns `:ok`
  """
  @spec delist(:squads, pid) :: :ok
  def delist(:squads, spinnable_pid) do
    GenServer.cast(@squads_pid, {:delist, spinnable_pid})
  end

  @doc """
  A public API for getting the current state of the Arena.

  Returns a map with member list
  """
  @spec introspect(:spinners) :: Map.t()
  def introspect(:spinners) do
    GenServer.call(@spinners_pid, :introspect)
  end

  @doc """
  A public API for getting the current state of the Arena.

  Returns a map with member list
  """
  @spec introspect(:squads) :: Map.t()
  def introspect(:squads) do
    GenServer.call(@squads_pid, :introspect)
  end

  @doc """
  Default process for starting a spinner arena.

  Returns `on_start` type.
  """
  @spec start_link(:spinners) :: on_start
  def start_link(:spinners), do: start_link(__MODULE__, %__MODULE__{}, name: @spinners_pid)

  @doc """
  Default process for starting a squad arena.

  Returns `on_start` type.
  """
  @spec start_link(:squads) :: on_start
  def start_link(:squads), do: start_link(__MODULE__, %__MODULE__{}, name: @squads_pid)

  @doc """
  Default implementation for starting a GenServer's linked process. Arena
  shouldn't be start manually in any case. Gyro, on start, will already create
  a spinner arena and a squad arena under its supervision tree for the
  application.

  Returns `on_start` type.
  """
  @spec start_link(String.t() | Atom.t(), %__MODULE__{}, Keyword.t()) :: on_start
  def start_link(name, state \\ %__MODULE__{}, opts \\ []) do
    GenServer.start_link(name, state, opts)
  end

  @doc """
  Once the GenServer is started successfully, the init function is invoked.
  For now, we just need to tell it to start spinning.

  Returns a tuple of `:ok` atom and the current state.
  """
  @spec init(%__MODULE__{}) :: {:ok, %__MODULE__{}}
  def init(state) do
    send(self(), :spin)
    {:ok, state}
  end

  @doc """
  Handle the introspect call to get the current state of the Arena.

  Returns a tuple of `:reply` atom, the message to respond to the caller with,
  and the new state to continue the process with for the next handler.
  """
  @spec handle_call(:introspect, pid, %__MODULE__{}) :: {:reply, %__MODULE__{}, %__MODULE__{}}
  def handle_call(:introspect, _from, state) do
    {:reply, state, state}
  end

  @doc """
  Add the given spinner id to member list in the state.

  Returns a tuple of `:noreply`, and the new state to continue the process
  with for the next handler.
  """
  @spec handle_cast({:enlist, pid}, %__MODULE__{}) :: {:noreply, %__MODULE__{}}
  def handle_cast({:enlist, spinner_pid}, state = %{members: members, size: size}) do
    Process.monitor(spinner_pid)
    state = %{state | members: Map.put(members, spinner_pid, spinner_pid), size: size + 1}
    {:noreply, state}
  end

  @doc """
  Remove the given spinner id from the member list in the state.

  Returns a tuple of `:noreply` and the new state to continue the process
  with for the next handler.
  """
  @spec handle_cast({:delist, pid}, %__MODULE__{}) :: {:noreply, %__MODULE__{}}
  def handle_cast({:delist, spinner_pid}, state = %{members: members, size: size}) do
    state = %{state | members: Map.delete(members, spinner_pid), size: size - 1}
    {:noreply, state}
  end

  @doc """
  Handle the `:DOWN` message from the Spinnables' processes we monitor on
  enlist.
  If the Spinnable's process is downed, we delist them from the Arena's
  roster.

  Returns a tuple of `:noreply` and the new state to continue the process
  with for the next handler, as given from the delist handler.
  """
  @spec handle_info({:DOWN, pid, :process, pid, Atom.t()}, %__MODULE__{}) ::
          {:noreply, %__MODULE__{}}
  def handle_info({:DOWN, _, :process, spinner_pid, _}, state) do
    handle_cast({:delist, spinner_pid}, state)
  end

  @doc """
  Handle the spinning which is where we update the state of the Arena at an
  interval.

  Returns a tuple of `:noreply` and the new state to continue the process
  with for the next handler.
  """
  @spec handle_info(:spin, %__MODULE__{}) :: {:noreply, %__MODULE__{}}
  def handle_info(:spin, state = %{members: pids, scoreboard: scoreboard}) do
    members =
      pids
      |> inspect_members

    scoreboard = Scoreboard.build(scoreboard, members)

    state = %{state | scoreboard: scoreboard, score: scoreboard.score, spm: scoreboard.spm}
    Process.send_after(self(), :spin, @timer)
    {:noreply, state}
  end

  # A private method for getting the latest state of processes in a given
  # list.
  @spec inspect_members(Enum.t()) :: Enum.t()
  defp inspect_members(members) do
    members
    |> Stream.map(fn {_, pid} ->
      Task.async(fn -> Spinnable.introspect(pid) end)
    end)
    |> Stream.map(&Task.await(&1))
    |> Enum.filter(&(!is_nil(&1)))
  end
end
