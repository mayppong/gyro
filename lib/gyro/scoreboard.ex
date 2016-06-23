defmodule Gyro.Scoreboard do
  alias __MODULE__
  alias Gyro.Spinner

  defstruct name: nil, score: 0, spm: 0,
    legendaries: [], heroics: [], latest: []

  @size 10

  @doc """
  Build a scoreboard based on the previous scoreboard given and a list of
  spinnable states.
  """
  def build(board \\ %Scoreboard{}, list) do
    latest = list |> latest
    heroics = list |> heroics
    legendaries = heroics |> legendaries(board.legendaries)

    %Scoreboard{board | latest: latest, heroics: heroics, legendaries: legendaries}
  end

  @doc """
  A method for iterating through a given list and return the sum of score and
  spm.
  """
  def total(list) do
    list
    |> Enum.reduce({0, 0}, fn(%{score: score, spm: spm}, {acc_score, acc_spm}) ->
      {acc_score + score, acc_spm + spm}
    end)
  end

  @doc """
  A method for finding the newest spinnables in the squad.
  This is done by iterating through members, sort them by their connected
  time, and take only the first 10 from the list.
  """
  def latest(list), do: list |> by_created |> chop

  @doc """
  This method is used for updating the heroic_spinnables during the spin. It
  collects the spinnable data by iterating through the spinnable roster and ask
  for the current spinnable state, then sort them by score before taking the
  top 10 players.
  """
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
  def legendaries(list, legends) do
    legends
    |> dedup(list)
    |> mark_dead
    |> Enum.concat(list)
    |> by_score
    |> chop
  end

  # Sort spinnables by their created at time.
  defp by_created(list), do: list |> Enum.sort(&(&1.created_at > &2.created_at))

  # Sort spinnables by their score.
  defp by_score(list), do: list |> Enum.sort(&(&1.score > &2.score))

  # Cap the size of the list
  defp chop(list, size \\ @size), do: list |> Enum.take(size)

  # Remove spinnables that have updated state.
  defp dedup([], _), do: []
  defp dedup(old, current) do
    old
    |> Enum.filter(fn(item) ->
      Enum.any?(current, &(&1.id == item.id))
    end)
  end

  # Set spinnables spm to 0 if their process is no longer in the system.
  defp mark_dead(spinnables) do
    spinnables
    |> Enum.map(fn(spinnable = %{id: pid, spm: spm}) ->
      if spm != 0 do
        case Process.alive?(pid) do
          false -> %Spinner{spinnable | spm: 0}
          true -> spinnable
        end
      else
        spinnable
      end
    end)
  end

end
