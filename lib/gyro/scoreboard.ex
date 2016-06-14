defmodule Gyro.Scoreboard do
  alias Gyro.Scoreboard
  alias Gyro.Spinner

  defstruct name: nil, score: 0, spm: 0,
    legendaries: [], heroics: [], latest: []

  def build(board \\ %Scoreboard{}, list) do
    board
    |> build_latest(list)
    |> build_heroics(list)
    |> build_legendaries
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

  # Private method for finding the newest spinners in the squad.
  # This is done by iterating through members, sort them by their connected
  # time, and take only the first 10 from the list.
  def build_latest(board, list) do
    latest = list
    |> Enum.sort(&(&1.created_at > &2.created_at))
    |> Enum.take(10)

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

    %Scoreboard{board | heroics: heroics}
  end

  # This method updates the legendary spinner list based on the new heroic
  # spinners. Unlike heroic, legendary spinners are an all-time score, so we
  # need to compare the score against existing legendary as well, even if the
  # spinner has left the system.
  def build_legendaries(board = %{heroics: heroes}), do: build_legendaries(board, heroes)
  def build_legendaries(board = %{legendaries: legends}, heroes) do
    legends = legends
    |> Enum.reject(fn(legend) ->
      Enum.any?(heroes, &(&1.id == legend.id))
    end)
    |> Enum.concat(heroes)
    |> Enum.sort(&(&1.score >= &2.score))
    |> Enum.take(10)
    |> Enum.map(fn(spinner = %{id: pid, spm: spm}) ->
      if spm != 0 do
        case Process.alive?(pid) do
          false -> %Spinner{spinner | spm: 0}
          true -> spinner
        end
      else
        spinner
      end
    end)

    %Scoreboard{board | legendaries: legends}
  end

end
