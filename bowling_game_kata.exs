ExUnit.start()

defmodule BowlingGame do
  use Agent

  @frames_per_game 10
  @rolls_per_frame 2
  @pins_per_frame 10

  def start_link do
    state = %{
      current_frame: 1,
      current_roll: 1,
      rolls: [],
      score: 0
    }

    Agent.start_link(fn -> state end)
  end

  def roll(game, number_of_pins) when number_of_pins > 0 do
    Agent.update(game, fn state ->
      new_roll = state.current_roll + 1
      new_frame = if state.current === @rolls_per_frame, do: state.current_frame + 1

      new_score =
        if roll_is_spare?(state) do
          number_of_pins * 2
        else
          case roll_is_strike?(state) do
            {true, previous_roll} -> previous_roll + number_of_pins
            _ -> number_of_pins
          end
        end

        %{
          state |
          rolls: [number_of_pins | state.rolls],
          score: new_score + state.score
        }
    end)
  end

  def score(game), do: Agent.get(game, &Map.get(&1, :score))

  defp roll_is_spare?(state) do
    previous_number_of_pins = 
      previous_rolls(state)
      |> Enum.sum()

    previous_number_of_pins === @pins_per_frame
  end

  defp roll_is_strike?(state) do
    if state.current_roll === 1 do
      case previous_rolls(state) do
        [@pins_per_frame, previous_roll] -> {true, previous_roll}
        _ -> false
      end
    end
  end

  defp previous_rolls(state), do: Enum.take(state.rolls, @rolls_per_frame * -1)
end

defmodule BowlingGame.Tests do
  use ExUnit.Case, async: true

  setup do
    {:ok, game} = BowlingGame.start_link()

    %{game: game}
  end

  test "rolling", %{game: game} do
    for _ <- 1..20, do: BowlingGame.roll(game, 1)

    assert BowlingGame.score(game) === 20
  end

  test "spare roll bonus is double the subsquent roll", %{game: game} do
    [5, 5, 5]
    |> Enum.each(&BowlingGame.roll(game, &1))

    assert BowlingGame.score(game) === 20
  end

  test "strike roll bonus is the sum of the subsquent two rolls", %{game: game} do
    [10, 3, 4]
    |> Enum.each(&BowlingGame.roll(game, &1))

    assert BowlingGame.score(game) === 20
  end
end
