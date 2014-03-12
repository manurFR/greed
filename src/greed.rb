class GreedGame

  def playGame
    puts 'Welcome to GREED'
    puts
    player_names = []
    while player_names.size < 2 do
      puts 'Please type the name of the players (two or more), separated by a comma:'
      player_names = gets.chomp.split(',').each { |name| name.strip! }
    end

  end

end

class GamePlayers
  def initialize(player_names)
    raise(ArgumentError, 'My argument should be an array') unless player_names.is_a?(Array)
    raise(ArgumentError, 'My argument should contain at least two elements') unless player_names.size >= 2
    raise(ArgumentError, 'The elements in the array should all be strings') unless player_names.all? { |name| name.is_a?(String) }
    @array_players = Array.new
    player_names.each do |name|
      player = GreedPlayer.new
      player.name = name
      @array_players << player
    end
    @current_index = 0
  end

  def next
    if @current_index >= @array_players.size
      @current_index = 0
    end
    current_player = @array_players[@current_index]
    @current_index += 1
    return current_player
  end
end

class GreedPlayer
  NB_OF_DICE = 5
  GETINTHEGAME_POINTS_REQUIRED = 300
  attr_accessor :turn_score, :total_score, :name
  attr_reader :final_round

  def initialize
    @turn_score = 0
    @total_score = 0
    @diceSet = DiceSet.new
    @final_round = false
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

    if reactToTurnScore
      puts "  In this turn, you have added #{turn_score} points to your score."
    elsif @turn_score > 0
      puts "  In this turn, your score of #{turn_score} points wasn't enough to \"get in the game\" (min. #{GETINTHEGAME_POINTS_REQUIRED} points required)."
    end

    puts "Your total score is: #{total_score} points."

    unless @final_round
      detectEndGame?
    end

    puts
  end

  def detectEndGame?
    if total_score >= 3000
      @final_round = true
      return true
    end
    return false
  end

  def reactToTurnScore
    if @turn_score >= GETINTHEGAME_POINTS_REQUIRED or @total_score >= GETINTHEGAME_POINTS_REQUIRED
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

if __FILE__ == $0
  #gp = GreedPlayer.new
  #gp.playTurn
  game = GreedGame.new
  game.playGame
end