defmodule Gyro.Squad.Supervisor do
  use Supervisor

  alias Gyro.Squad

  @pid {:global, __MODULE__}

  @doc """
  The `start_link` is used by `Gyro.Supervisor` to start a supervisor itself.
  We are passing an atom :ok and an initial state to it as a place holder and
  give a global name scope so it can be referenced anywhere in the network.
  """
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: @pid])
  end

  @doc """
  This is a function we call to form a new Squad under this supervisor. We're
  only accepting just the name of the squad for now with the supervisor
  deciding on the initial state. For now, the client API won't have access to
  set the initial state of the Squad.
  """
  def start_child(name, state) do
    Supervisor.start_child(@pid, [{:global, name}, state])
  end

  @doc """
  The init function is required by the Supervisor interface thought it's not
  actually doing anything but start a dummy job with no restart plan. It's
  only use for declaring the `:simple_one_for_one` strategy for the
  Supervisor.
  """
  def init(:ok) do
    children = [worker(Squad, [], restart: :temporary)]
    supervise(children, strategy: :simple_one_for_one)
  end
end
