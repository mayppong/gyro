defmodule Gyro.Scoreboard do
  alias Gyro.Scoreboard

  defstruct name: nil, score: 0, spm: 0,
    legendaries: [], heroics: [], latest: []

  def build(board \\ %Scoreboard{}, list) do
    board
    |> build_latest(list)
    |> build_heroics(list)
  end

  # Private method for finding the newest spinners in the squad.
  # This is done by iterating through members, sort them by their connected
  # time, and take only the first 10 from the list.
  def build_latest(board, list) do
    latest = list
    |> Enum.sort(&(&1.created_at > &2.created_at))
    |> Enum.take(10)
    |> minify

    %Scoreboard{board | latest: latest}
  end

  # This method is used for updating the heroic_spinners during the spin. It
  # collects the spinner data by iterating through the spinner roster and ask
  # for the current spinner state, then sort them by score before taking the
  # top 10 players.
  def build_heroics(board, list) do
    heroics = list
    |> Enum.sort(&(&1.score >= &2.score))
    |> Enum.take(10)
    |> minify

    %Scoreboard{board | heroics: heroics}
  end

  # This method updates the legendary spinner list based on the new heroic
  # spinners. Unlike heroic, legendary spinners are an all-time score, so we
  # need to compare the score against existing legendary as well, even if the
  # spinner has left the system.
  def build_legendaries(board = %{legendaries: legends}, heroes) do
    legends = legends
    |> Enum.concat(heroes)
    |> Enum.sort(&(&1.score >= &2.score))
    |> Enum.take(10)

    %Scoreboard{board | legendaries: legends}
  end

  # Private method for cleaning up spinner state before we add them to the
  # list. There are some data in each spinner where we might not care for.
  # This is a good place where we can clean them up and store just the data
  # we need.
  # TODO: once we can JSONify this, we won't need this method any more
  defp minify(list) do
    list
    |> Enum.map(fn(item) ->
      item
      |> Map.delete(:created_at)
      |> Map.delete(:squad_pid)
    end)
  end

end
