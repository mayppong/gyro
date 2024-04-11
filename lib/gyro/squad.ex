defmodule Gyro.Squad do
  @moduledoc """
  The `Squad` module implements a GenServer process for storing information
  related to a squad, with each squad having its own process, registered
  as a name process in the global scope.

  It's also a context module providing interface for working with the
  GenServer process as well.
  """
  use Gyro.Arena.Spinnable

  alias Gyro.Arena
  alias Gyro.Arena.Spinnable
  alias Gyro.Scoreboard
  alias Gyro.Squad.DynamicSupervisor

  @type t :: %__MODULE__{
          id: pid(),
          name: String.t(),
          members: Map.t(),
          score: Integer.t(),
          spm: Integer.t(),
          created_at: DateTime.t(),
          scoreboard: Scoreboard.t()
        }

  @derive {Jason.Encoder, except: [:id, :members]}
  defstruct id: nil,
            name: nil,
            created_at: DateTime.utc_now(),
            members: %{},
            score: 0,
            spm: 0,
            scoreboard: %Scoreboard{}

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
  @spec form(String.t()) :: {:ok, pid()} | {:error, Any.t()} | :ignore
  def form(name) do
    case exists?(name) do
      true ->
        {:ok, {:global, name}}

      false ->
        DynamicSupervisor.start_child(name, %__MODULE__{name: name})
        |> case do
          {:ok, squad_pid} ->
            Arena.enlist(:squads, squad_pid)
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
  Stop the given squad GenServer.
  """
  @spec disband(pid(), term()) :: :ok
  def disband(squad_pid, reason \\ :normal) do
    GenServer.stop(squad_pid, reason)
  end

  @doc """
  Add the given spinnable to a squad of a given name. If the squad doesn't
  already exist, also start it.
  """
  @spec enlist(String.t(), pid()) :: {:ok, pid()} | {:error, Any.t()} | :ignore
  def enlist(name, spinnable_pid) do
    delist(spinnable_pid)

    case form(name) do
      {:ok, squad_pid} ->
        squad_pid |> GenServer.cast({:enlist, spinnable_pid})
        spinnable_pid |> Spinnable.update(:squad_pid, squad_pid)
        spinnable_pid |> Spinnable.update(:squad_name, name)
        {:ok, squad_pid}

      error ->
        error
    end
  end

  @doc """
  Remove the given spinnable from the squad stored in its state.
  """
  @spec delist(pid()) :: :ok
  def delist(spinnable_pid) when is_pid(spinnable_pid) do
    %{squad_pid: squad_pid} = Spinnable.introspect(spinnable_pid)

    case is_pid(squad_pid) do
      true -> delist(squad_pid, spinnable_pid)
      _ -> :ok
    end
  end

  @doc """
  Remove the spinnable from the given squad.
  """
  @spec delist(pid(), pid()) :: :ok
  def delist(squad_pid, spinnable_pid) do
    GenServer.cast(squad_pid, {:delist, spinnable_pid})
    spinnable_pid |> Spinnable.update(:squad_pid, nil)
    spinnable_pid |> Spinnable.update(:squad_name, nil)
  end

  @doc """
  Start a new GenServer process for a squad.
  The GenServer will be registered in the global registry with the name. This
  means the squad name is unique and can be referenced by name from anywhere
  in the system without the process id.
  """
  @spec start_link(Sting.t(), __MODULE__.t()) :: {:ok, pid()} | {:error, Any.t()} | :ignore
  def start_link(name, state) do
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @doc """
  Once the GenServer is started successfully, the init function is invoked.
  For now, we just need to tell it to start spinning.
  """
  @spec init(Map.t()) :: {:ok, __MODULE__.t()}
  def init(state = %{name: name}) do
    state = Map.put(state, :id, {:global, name})
    send(self(), :spin)
    {:ok, state}
  end

  @doc """
  Handle adding a new spinnable to the squad.
  The new spinnable is stored in the member list as a map.
  """
  @spec handle_cast({:enlist, pid()}, __MODULE__.t()) :: {:noreply, __MODULE__.t()}
  def handle_cast({:enlist, spinnable_pid}, state = %__MODULE__{members: members}) do
    Process.monitor(spinnable_pid)
    members = Map.put(members, spinnable_pid, spinnable_pid)
    state = Map.put(state, :members, members)
    {:noreply, state}
  end

  @doc """
  Handle a member leaving the squad.
  We need to remove the member from the member list. The ideal situation
  would be to find the member from the list by map. However, since we're
  using the spinnable pid as "key"-ish right now, we can't look up the member
  listing map by key right now.
  """
  @spec handle_cast({:delist, pid()}, __MODULE__.t()) :: {:noreply, __MODULE__.t()}
  def handle_cast({:delist, quitter_pid}, state = %__MODULE__{members: members}) do
    members = Map.delete(members, quitter_pid)
    state = Map.put(state, :members, members)

    {:noreply, state}
  end

  @doc """
  Handle the `:DOWN` message from the Spinnables' process we monitor on enlist.
  If the Spinnable process is downed, we delist them from the Squad.
  """
  @spec handle_info({:DOWN, pid()}, __MODULE__.t()) :: {:noreply, __MODULE__.t()}
  def handle_info({:DOWN, _ref, :process, spinnable_pid, _}, state) do
    handle_cast({:delist, spinnable_pid}, state)
  end

  # Handle `spinning` which is where we update the current state of the squad
  # at a set interval.
  # A new process is spun up for each member to introspect the state
  # asynchronously. Once we have all members data, we can continue on with the
  # calculations.
  @spec handle_info(:spin, __MODULE__.t()) :: {:noreply, __MODULE__.t()}
  def handle_info(:spin, state = %__MODULE__{members: pids, scoreboard: scoreboard}) do
    members =
      pids
      |> inspect_members

    scoreboard_task = Task.async(fn -> Scoreboard.build(scoreboard, members) end)
    score_task = Task.async(fn -> Scoreboard.total(members) end)

    {score, spm} = Task.await(score_task)
    scoreboard = Task.await(scoreboard_task)

    Process.send_after(self(), :spin, @timer)
    {:noreply, %{state | score: score, spm: spm, scoreboard: scoreboard}}
  end

  # A private method for getting the latest state of processes in a given
  # list.
  @spec inspect_members(Map.t()) :: Enum.t()
  defp inspect_members(members) do
    members
    |> Stream.map(fn {_, pid} ->
      Task.async(fn -> Spinnable.introspect(pid) end)
    end)
    |> Stream.map(&Task.await(&1))
    |> Enum.filter(&(!is_nil(&1)))
  end
end
