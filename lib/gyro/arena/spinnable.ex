defmodule Gyro.Arena.Spinnable do
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
  def exists?(nil), do: false
  def exists?(name) when is_bitstring(name), do: exists?({:global, name})

  def exists?(pid) when is_pid(pid) do
    Process.alive?(pid)
  end

  def exists?(name), do: GenServer.whereis(name) |> exists?

  @doc """
  Inspect a list of pids for its state asynchronously.
  """
  def introspect(list) when is_list(list) do
    list
    |> Stream.map(fn {_, pid} ->
      Task.async(fn -> introspect(pid) end)
    end)
    |> Stream.map(&Task.await(&1))
    |> Enum.filter(&(!is_nil(&1)))
  end

  @doc """
  Inspect the current state of the specified pid. If the process is not
  found, the function will catch the error message thrown by GenServer and
  return `nil` value as a result instead.
  """
  def introspect(pid) do
    try do
      introspect!(pid)
    catch
      :exit, {:noproc, _} -> nil
      :exit, _ -> nil
    end
  end

  @doc """
  Inspect the current state of the specified pid. If the spinner is not
  found, GenServer will, by default, throw a message.
  """
  def introspect!(pid) do
    GenServer.call(pid, :introspect)
  end

  @doc """
  Update spinnable data.
  """
  def update(spinner_pid, key, value) do
    GenServer.cast(spinner_pid, {:update, key, value})
  end
end
