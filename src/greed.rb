class GreedGame
  attr_reader :final_round

  def initialize
    @final_round = false
  end

  def playGame
    puts 'Welcome to GREED'
    puts
    player_names = []
    while player_names.size < 2 do
      puts 'Please type the name of the players (two or more), separated by a comma:'
      player_names = gets.chomp.split(',').each { |name| name.strip! }
      puts
    end

    players = GamePlayers.new(player_names)

    current_player = players.next
    while current_player do # nil (ie no more players) is false
      puts "#{current_player.name.capitalize}, it's your turn. Your total score is currently #{current_player.total_score} points."

      current_player.playTurn

      unless @final_round
        if detectFinalRound?(current_player.total_score)
          puts "#{current_player.name.capitalize} has reached 3000 points. All the other players can play one last turn and then the game will be over."
          puts
          sleep(2)
          players.setCurrentPlayerAsStoppingPlayer
        end
      end
      current_player = players.next
      sleep(1)

      puts current_player ? 'Current Scores' : ' Final Scores'
      puts '=============='
      puts

      players.players_by_scores.each_with_index do |player, index|
        puts "#{index+1}. #{player.name.capitalize}: #{player.total_score} points"
      end
      puts
    end
  end

  def detectFinalRound?(total_score)
    if total_score >= 3000
      @final_round = true
      return true
    end
    return false
  end
end

class GamePlayers
  def initialize(player_names)
    raise(ArgumentError, 'The argument should be an array') unless player_names.is_a?(Array)
    raise(ArgumentError, 'The argument should contain at least two elements') unless player_names.size >= 2
    raise(ArgumentError, 'The elements in the array should all be strings') unless player_names.all? { |name| name.is_a?(String) }
    @array_players = Array.new
    player_names.each { |name| @array_players << GreedPlayer.new(name) }
    @current_index = -1
    @stopping_index = nil
  end

  def next
    @current_index += 1
    if @current_index >= @array_players.size
      @current_index = 0
    end
    (@current_index == @stopping_index) ? nil : @array_players[@current_index]
  end

  def setCurrentPlayerAsStoppingPlayer
    @stopping_index = @current_index
  end

  def players_by_scores
    @array_players.sort { |elt, other| elt.total_score <=> other.total_score }.reverse
  end
end

class GreedPlayer
  NB_OF_DICE = 5
  GETINTHEGAME_POINTS_REQUIRED = 300
  attr_accessor :turn_score, :total_score, :name

  def initialize(name)
    @name = name
    @total_score = 0
    @diceSet = DiceSet.new
  end

  def playTurn
    @turn_score = 0
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
    puts
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
    return gets.chomp.upcase[0] != 'N'
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
  game = GreedGame.new
  game.playGame
end