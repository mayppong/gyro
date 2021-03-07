defmodule Gyro.Squad.DynamicSupervisor do
  @moduledoc """
  The `DynamicSupervisor` implements `DynamicSupervisor` behaviour to allow
  `Gyro` application to manage `Spinnable` GenServer processes to be added
  to the supervision tree dynamically as new spinners or squads are added.
  """
  use DynamicSupervisor

  alias Gyro.Squad

  @pid {:global, __MODULE__}

  @doc """
  The `start_link` is used by `Gyro.Supervisor` to start a supervisor itself.
  We are passing an atom :ok and an initial state to it as a place holder and
  give a global name scope so it can be referenced anywhere in the network.
  """
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: @pid)
  end

  @doc """
  This is a function we call to form a new Squad under this supervisor.
  The DynamicSupervisor requires the `id` of a child worker even though the
  GenServer will also be doing name registration. Not sure why this behaviour,
  but for now, we're setting the name twice as you can see in the spec, the
  term `{:global, name}` is set as `id` as pass as param to `Squad` GenServer
  we're starting
  """
  def start_child(name, state) do
    spec = %{start: {Squad, :start_link, [{:global, name}, state]}, id: {:global, name}}
    DynamicSupervisor.start_child(@pid, spec)
  end

  @doc """
  The init function is required by the Supervisor interface for any processing
  prior to initializing a supervisor.
  """
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
