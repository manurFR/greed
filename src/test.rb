require 'test/unit'
require File.dirname(__FILE__) + '/greed'

class GreedPlayerTest < Test::Unit::TestCase

  def setup
    @greed_player = GreedPlayer.new
  end

  def test_greedplayer_exists
    assert_nothing_raised do
      GreedPlayer.new
    end
  end

  def test_positive_score_is_accumulated_in_turn_score
    assert_equal 0, @greed_player.turn_score
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