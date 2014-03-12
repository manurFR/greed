class GreedPlayer
  NB_OF_DICE = 5
  attr_accessor :turn_score
  attr_reader :total_score

  def initialize
    @turn_score = 0
    @total_score = 0
    @diceSet = DiceSet.new
  end

  def playTurn
    rollNumber = 0

    dicesToRoll = NB_OF_DICE
    while dicesToRoll > 0 do
      rollNumber += 1
      @diceSet.roll(dicesToRoll)

      scoring_dice, roll_score, non_scoring_dice = score(@diceSet.values)
      puts "Roll #{rollNumber}: #{@diceSet.values.sort}"

      if reactToRollScore(roll_score)
        puts "  => scored #{roll_score} points with #{scoring_dice}"
        puts "  Accumulated score for this turn: #{turn_score} points"
        if non_scoring_dice.size > 0
          puts "  Non-Scoring Dice: #{non_scoring_dice}"
          puts 'Would you like to re-roll ' + pluralize(non_scoring_dice.size, %w(die dice)) + '? [Y,n]'
        else
          puts 'Would you like to roll a new series of 5 dice? [Y,n]'
        end

        okToRoll = askForAuthorization?
        dicesToRoll = determineDicesToRoll(okToRoll, non_scoring_dice.size)
      else
        puts 'No points in this roll! You lose all of this turn\'s points, and your turn is over...'
        break
      end
    end # while dicesToRoll > 0

    reactToTurnScore
        # TODO puts info sur le total score dans les deux cas

    puts "* Total points earned in this turn: #{turn_score}."
  end

  def reactToTurnScore
    if @turn_score >= 300 or @total_score >= 300
      @total_score += @turn_score
      return @turn_score > 0
    end
    return false
  end

  def determineDicesToRoll(okToRoll, numberOfRemainingDice)
    if okToRoll
      numberOfRemainingDice == 0 ? NB_OF_DICE : numberOfRemainingDice
    else
      0
    end
  end

  def askForAuthorization?
    return gets.chomp.upcase[0] == 'Y'
  end

  def pluralize(number, options)
    if number <= 1
      return "#{number} #{options[0]}"
    else
      return "#{number} #{options[-1]}"
    end
  end

  def reactToRollScore(roll_score)
    if roll_score > 0
      @turn_score += roll_score
      return true
    else
      @turn_score = 0
    end
    return false
  end
end

class DiceSet
  attr_reader :values

  def roll(len)
    @values = []
    len.times { @values << rand(6) + 1 }
  end
end

def score(dice)
  # return [ [scoring_dice], score, [non-scoring dice] ]
  if dice.size == 0
    return [[], 0, []]
  end
  scoring_dice = []
  non_scoring_dice = dice.dup
  dice_count = Hash.new(0)
  dice.each { |item| dice_count[item] += 1 }
  score = 0
  dice_count.each do |value, occurrences|
    # triplets
    nb_triplets = occurrences / 3
    nb_dice_in_triplets = nb_triplets * 3
    if value == 1
      score += nb_triplets * 1000
    else
      score += nb_triplets * value * 100
    end
    nb_dice_in_triplets.times do
      idx = non_scoring_dice.find_index(value)
      non_scoring_dice.delete_at(idx)
    end
    scoring_dice.push(*Array.new(nb_dice_in_triplets, value)) # Array.new(size, default_item)

    remainder = occurrences % 3

    # remaining 5s
    if value == 5 and remainder > 0
      score += remainder * 50
      non_scoring_dice.delete(5) # let's delete all remaining 5s
      scoring_dice.push(*Array.new(remainder, 5))
    end
    # remaining 1s
    if value == 1 and remainder > 0
      score += remainder * 100
      non_scoring_dice.delete(1) # let's delete all remaining 1s
      scoring_dice.push(*Array.new(remainder, 1))
    end
  end

  return [scoring_dice, score, non_scoring_dice]
end