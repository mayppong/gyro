defmodule Gyro.Arena.Spinnable do
  @moduledoc """
  The `Spinnable` module provides a behaviour for implementing GenServer
  processes meant to represent the functionality of `Spinner` and `Squad`.
  This includes an interface for working with those GenServer processes
  within its respective context such as a way to get, and update data.
  """

  alias __MODULE__

  defmacro __using__(_) do
    quote do
      use GenServer

      def introspect(pid), do: Spinnable.introspect(pid)
      def exists?(pid), do: Spinnable.exists?(pid)
      def update(pid, key, value), do: Spinnable.update(pid, key, value)

      @doc """
      Handle a call to get the current state stored in the process.
      """
      def handle_call(:introspect, _from, state) do
        {:reply, state, state}
      end

      @doc """
      Handle updating a key in the current state.
      """
      def handle_cast({:update, key, value}, state) do
        state = Map.put(state, key, value)
        {:noreply, state}
      end

      defoverridable introspect: 1, exists?: 1, update: 3
    end
  end

  @doc """
  Check if spinner pid is still alive.
  The function is a convenient function for resolving
  """
  @spec exists?(String.t() | List.t() | {:global, String.t()}) :: boolean()
  def exists?(nil), do: false
  def exists?(name) when is_bitstring(name), do: exists?({:global, name})

  def exists?(pid) when is_pid(pid) do
    Process.alive?(pid)
  end

  def exists?(name = {:global, _}), do: GenServer.whereis(name) |> exists?

  @doc """
  Inspect the current state of the specified pid. If the process is not
  found, the function will catch the error message thrown by GenServer and
  return `nil` value as a result instead.

  If a list of pids is given, we fetch information for each in a stream for
  its state asynchronously. If the state returned from the pid is `nil`, the
  result is removed from the list.
  """
  @spec introspect(pid() | {:global, pid()} | List.t()) :: Struct.t() | List.t()
  def introspect(list) when is_list(list) do
    list
    |> Stream.map(fn {_, pid} ->
      Task.async(fn -> introspect(pid) end)
    end)
    |> Stream.map(&Task.await(&1))
    |> Enum.filter(&(!is_nil(&1)))
  end

  def introspect(pid) do
    introspect!(pid)
  catch
    :exit, {:noproc, _} -> nil
    :exit, _ -> nil
  end

  @doc """
  Inspect the current state of the specified pid. If the spinner is not
  found, GenServer will, by default, throw a message.
  """
  @spec introspect!(pid()) :: Struct.t()
  def introspect!(pid) do
    GenServer.call(pid, :introspect)
  end

  @doc """
  Update spinnable data.
  """
  @spec update(pid(), Any.t(), Any.t()) :: :ok
  def update(spinner_pid, key, value) do
    GenServer.cast(spinner_pid, {:update, key, value})
  end
end
