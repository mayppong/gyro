defmodule Gyro.Scoreboard do
  @moduledoc """
  The `Scoreboard` is an implmenetation of the GenServer for storing aggregated
  information about the top scores from 3 different categories:
  - Legendary refers to highest score of any spinnable process the system has
    seen (including the ones that's offline)
  - Heroic refers to highest score *active* spinnable process
  - Latest refers to newest spinnable process joining the system

  The scoreboard is currently used for both ranking spinner (user), and squad,
  but separately.
  """

  alias Gyro.Arena.Spinnable

  @type t :: %__MODULE__{
          name: String.t(),
          score: Integer.t(),
          spm: Integer.t(),
          size: Integer.t(),
          legendaries: List.t(),
          heroics: List.t(),
          latest: List.t()
        }

  @derive Jason.Encoder
  defstruct name: nil, score: 0, spm: 0, size: 0, legendaries: [], heroics: [], latest: []

  @size 10

  @doc """
  Build a scoreboard based on the previous scoreboard given and a list of
  spinnable states.
  """
  @spec build(__MODULE__.t(), List.t()) :: __MODULE__.t()
  def build(board \\ %__MODULE__{}, list) do
    size = list |> size()
    latest = list |> latest()
    heroics = list |> heroics()
    legendaries = heroics |> legendaries(board.legendaries)

    %__MODULE__{board | size: size, latest: latest, heroics: heroics, legendaries: legendaries}
  end

  @doc """
  A method for iterating through a given list and return the sum of score and
  spm.
  """
  @spec total(List.t()) :: List.t()
  def total(list) do
    list
    |> Enum.reduce({0, 0}, fn %{score: score, spm: spm}, {acc_score, acc_spm} ->
      {acc_score + score, acc_spm + spm}
    end)
  end

  @doc """
  Counting number of members. It's currently just calling the `Enum.count`
  directly. However, we might want to expand in the future to
  """
  @spec size(List.t()) :: Integer.t()
  def size(list), do: list |> Enum.count()

  @doc """
  A method for finding the newest spinnables in the squad.
  This is done by iterating through members, sort them by their connected
  time, and take only the first 10 from the list.
  """
  @spec latest(List.t()) :: List.t()
  def latest(list), do: list |> by_created |> chop

  @doc """
  This method is used for updating the heroic_spinnables during the spin. It
  collects the spinnable data by iterating through the spinnable roster and ask
  for the current spinnable state, then sort them by score before taking the
  top 10 players.
  """
  @spec heroics(List.t()) :: List.t()
  def heroics(list), do: list |> by_score |> chop

  @doc """
  This method updates the legendary spinnable list based on the new heroic
  spinnables. Unlike heroic, legendary spinnables are an all-time score, so we
  need to compare the score against existing legendary as well, even if the
  spinnable has left the system.
  We're iterating by the legends instead of the list because this gives us a
  logical point where there could be less enumerable items than the list size
  after `dedup`. It allows us to `mark_dead` the least amount of spinnables
  which is most likely to be the bottleneck in the entire process since we
  have to message multiple GenServer processes to gather the states.
  """
  @spec legendaries(List.t(), List.t()) :: List.t()
  def legendaries(list, []), do: list |> heroics

  def legendaries(list, legends) do
    legends
    |> dedup(list)
    |> mark_dead
    |> Enum.concat(list)
    |> heroics
  end

  # Sort spinnables by their created at time.
  @spec by_created(List.t()) :: List.t()
  defp by_created(list), do: list |> Enum.sort(&(&1.created_at > &2.created_at))

  # Sort spinnables by their score.
  defp by_score(list), do: list |> Enum.sort(&(&1.score > &2.score))

  # Cap the size of the list
  defp chop(list, size \\ @size), do: list |> Enum.take(size)

  # Remove spinnables that have updated state.
  defp dedup([], _), do: []

  defp dedup(old, current) do
    old
    |> Enum.reject(fn item ->
      Enum.any?(current, &(&1.id == item.id))
    end)
  end

  # Set spinnables spm to 0 if their process is no longer in the system.
  defp mark_dead(spinnables) do
    spinnables
    |> Stream.map(fn spinnable ->
      if alive?(spinnable) do
        spinnable
      else
        %{spinnable | spm: 0}
      end
    end)
  end

  defp alive?(%{id: pid, spm: spm}),
    do: spm != 0 and Spinnable.exists?(pid)
end
