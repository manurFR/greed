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