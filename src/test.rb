require 'test/unit'
require File.dirname(__FILE__) + '/greed'

unless respond_to? :assert_raise_with_message
  def assert_raise_with_message(exception, expected, msg = nil, &block)
    case expected
      when String
        assert = :assert_equal
      when Regexp
        assert = :assert_match
      else
        raise TypeError, "Expected #{expected.inspect} to be a kind of String or Regexp, not #{expected.class}"
    end

    ex = assert_raise(exception, *msg) {yield}
    msg = message(msg, "") {"Expected Exception(#{exception}) was raised, but the message doesn't match"}

    if assert == :assert_equal
      assert_equal(expected, ex.message, msg)
    else
      msg = message(msg) { "Expected #{mu_pp expected} to match #{mu_pp ex.message}" }
      assert expected =~ ex.message, msg
      block.binding.eval("proc{|_|$~=_}").call($~)
    end
    ex
  end
end

class GreedGameTest < Test::Unit::TestCase
  def setup
    @game = GreedGame.new
  end

  def test_final_round_starts_if_the_total_score_reaches_3000_points
    assert_equal false, @game.final_round

    assert_equal false, @game.detectFinalRound?(450)
    assert_equal false, @game.final_round

    assert_equal true, @game.detectFinalRound?(3000)
    assert_equal true, @game.final_round
  end
end

class GamePlayersTest < Test::Unit::TestCase
  def setup
    @players = GamePlayers.new(%w(albert bertha carl diana))
  end

  def test_initialize_argument_should_be_a_array_of_at_least_two_strings
    assert_raise_with_message(ArgumentError, 'The argument should be an array') do
      GamePlayers.new('hello')
    end
    assert_raise_with_message(ArgumentError, 'The argument should contain at least two elements') do
      GamePlayers.new(['hello'])
    end
    assert_raise_with_message(ArgumentError, 'The elements in the array should all be strings') do
      GamePlayers.new([1,8,6])
    end
    assert_nothing_raised do
      GamePlayers.new(['hello', 'world'])
    end
  end

  def test_next_should_return_all_players_in_the_right_order
    albert = @players.next
    assert_equal true, albert.is_a?(GreedPlayer)
    assert_equal 'albert', albert.name
    bertha = @players.next
    assert_equal true, bertha.is_a?(GreedPlayer)
    assert_equal 'bertha', bertha.name
    carl = @players.next
    assert_equal true, carl.is_a?(GreedPlayer)
    assert_equal 'carl', carl.name
    diana = @players.next
    assert_equal true, diana.is_a?(GreedPlayer)
    assert_equal 'diana', diana.name
  end

  def test_next_should_wrap_to_the_beginning
    4.times { @players.next }
    albert_again = @players.next
    assert_not_nil albert_again
    assert_equal 'albert', albert_again.name
  end

  def test_once_a_stopping_player_is_defined_then_his_next_appearance_should_instead_return_nil
    6.times { assert_not_nil @players.next } # at least one full loop without nil
    @players.setCurrentPlayerAsStoppingPlayer # bertha is the stopping player
    3.times { assert_not_nil @players.next } # each of the others can play once
    assert_equal true, @players.next.nil?
  end

  def test_scores
    albert = @players.next
    albert.total_score = 500
    bertha = @players.next
    bertha.total_score = 3820
    carl = @players.next
    carl.total_score = 2900
    diana = @players.next
    diana.total_score = 1150

    assert_equal [bertha, carl, diana, albert], @players.players_by_scores
  end
end

class GreedPlayerTest < Test::Unit::TestCase
  def setup
    @greed_player = GreedPlayer.new('myName')
  end

  def test_positive_score_is_accumulated_in_turn_score
    assert_equal nil, @greed_player.turn_score
    assert_equal false, @greed_player.reactToRollScore(-5)
    assert_equal 0, @greed_player.turn_score
    assert_equal false, @greed_player.reactToRollScore(0)
    assert_equal 0, @greed_player.turn_score
    assert_equal true, @greed_player.reactToRollScore(25)
    assert_equal 25, @greed_player.turn_score
    assert_equal true, @greed_player.reactToRollScore(15)
    assert_equal 40, @greed_player.turn_score
  end

  def test_pluralize
    word_options = %w(knife knives)
    assert_equal '1 knife', @greed_player.pluralize(1, word_options)
    assert_equal '0 knife', @greed_player.pluralize(0, word_options)
    assert_equal '-1 knife', @greed_player.pluralize(-1, word_options)
    assert_equal '2 knives', @greed_player.pluralize(2, word_options)
    assert_equal '486 knives', @greed_player.pluralize(486, word_options)
  end

  def test_determineDicesToRoll
    assert_equal 0, @greed_player.determineDicesToRoll(false, 3)
    assert_equal 3, @greed_player.determineDicesToRoll(true, 3)
    assert_equal 5, @greed_player.determineDicesToRoll(true, 0)
  end

  def test_this_turns_score_is_kept_only_if_its_larger_than_300_points_or_total_score_is_already_larger
    assert_equal 0, @greed_player.total_score
    @greed_player.turn_score = 100
    assert_equal false, @greed_player.reactToTurnScore
    assert_equal 0, @greed_player.total_score
    @greed_player.turn_score = 300
    assert_equal true, @greed_player.reactToTurnScore
    assert_equal 300, @greed_player.total_score
    @greed_player.turn_score = 100
    assert_equal true, @greed_player.reactToTurnScore
    assert_equal 400, @greed_player.total_score
    @greed_player.turn_score = 0 # case of a roll that doesn't score anything, we expect false although total_score is >= 300
    assert_equal false, @greed_player.reactToTurnScore
    assert_equal 400, @greed_player.total_score
  end
end

#noinspection RubyQuotedStringsInspection
class DiceSetTest < Test::Unit::TestCase
  def test_can_create_a_dice_set
    dice = DiceSet.new
    assert_not_nil dice
  end

  def test_rolling_the_dice_returns_a_set_of_integers_between_1_and_6
    dice = DiceSet.new

    dice.roll(5)
    assert dice.values.is_a?(Array), "should be an array"
    assert_equal 5, dice.values.size
    dice.values.each do |value|
      assert value >= 1 && value <= 6, "value #{value} must be between 1 and 6"
    end
  end

  def test_dice_values_do_not_change_unless_explicitly_rolled
    dice = DiceSet.new
    dice.roll(5)
    first_time = dice.values
    second_time = dice.values
    assert_equal first_time, second_time
  end

  def test_dice_values_should_change_between_rolls
    dice = DiceSet.new

    dice.roll(5)
    first_time = dice.values

    dice.roll(5)
    second_time = dice.values

    assert_not_equal first_time, second_time,
                     "Two rolls should not be equal"

    # THINK ABOUT IT:
    #
    # If the rolls are random, then it is possible (although not
    # likely) that two consecutive rolls are equal.  What would be a
    # better way to test this?
  end

  def test_you_can_roll_different_numbers_of_dice
    dice = DiceSet.new

    dice.roll(3)
    assert_equal 3, dice.values.size

    dice.roll(1)
    assert_equal 1, dice.values.size
  end
end

class ScoreTest < Test::Unit::TestCase
  def test_score_of_an_empty_list_is_zero
    assert_equal [[], 0, []], score([])
  end

  def test_score_of_a_single_roll_of_5_is_50
    assert_equal [[5], 50, []], score([5])
  end

  def test_score_of_a_single_roll_of_1_is_100
    assert_equal [[1], 100, []], score([1])
  end

  def test_score_of_multiple_1s_and_5s_is_the_sum_of_individual_scores
    assert_equal [[1,1,5,5], 300, []], score([1,5,5,1])
  end

  def test_score_of_single_2s_3s_4s_and_6s_are_zero
    assert_equal [[], 0, [2,3,4,6]], score([2,3,4,6])
  end

  def test_score_of_a_triple_1_is_1000
    assert_equal [[1,1,1], 1000, []], score([1,1,1])
  end

  def test_score_of_other_triples_is_100x
    assert_equal [[2,2,2], 200, []], score([2,2,2])
    assert_equal [[3,3,3], 300, []], score([3,3,3])
    assert_equal [[4,4,4], 400, []], score([4,4,4])
    assert_equal [[5,5,5], 500, []], score([5,5,5])
    assert_equal [[6,6,6], 600, []], score([6,6,6])
  end

  def test_score_of_mixed_is_sum
    assert_equal [[2,2,2,5],   250,  [3]], score([2,5,2,2,3])
    assert_equal [[5,5,5,5],   550,  []] , score([5,5,5,5])
    assert_equal [[1,1,1,1],   1100, []] , score([1,1,1,1])
    assert_equal [[1,1,1,1,1], 1200, []] , score([1,1,1,1,1])
    assert_equal [[1,1,1,1,5], 1150, []] , score([1,1,1,5,1])
  end
end