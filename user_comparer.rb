def simple_count_compare(tags_a, tags_b)
  to_loop = tags_a.count > tags_b.count ? tags_a : tags_b
  other = tags_a.count > tags_b.count ? tags_b : tags_a
  common = 0
  different = 0
  to_loop.each do |key, value|
    if value.to_i && other[key].to_i
      common += 1
    else
      different += 1
    end
  end

  common.to_f / different.to_f
end

# Given two Hashses of :key => probabilty,
# calculate the KL-divergence of the two
def kl_from_probability_distributions(p_a, p_b)
  p_a.inject(0.0) do |sum, values|
    sum if p_b[values[0]] == 0 || values[1] == 0

    sum + Math.log(values[1].to_f / p_b[values[0]])
  end
end

# Compare to distributions of tags using the kl-divergence (http://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence)
# metric. Since it is not symmetrical, we calculate it both ways.
def kl_divergence(tags_a, tags_b)

  all_words = tags_a.keys.concat(tags_b.keys).uniq
  num_tags_in_a = tags_a.inject(0) { |count, ar| count + ar[1].to_i }
  num_tags_in_b = tags_b.inject(0) { |count, ar| count + ar[1].to_i }

  # calculate the probability distributions for the tags
  p_a = {}
  p_b = {}
  all_words.each do |word|
    if tags_a[word]
      p_a[word] = tags_a[word].to_f / num_tags_in_a
    else
      p_a[word] = 0.0
    end

    if tags_b[word]
      p_b[word] = tags_b[word].to_f / num_tags_in_b
    else
      p_b[word] = 0.0
    end
  end

  # calculate the metric
  kl_a = kl_from_probability_distributions(p_a, p_b)
  kl_b = kl_from_probability_distributions(p_b, p_a)

  kl_a, kl_b
end

def tags_for_user(user_id)
  # return an array of tags for that user.
  # How to compare two users?
end

def compare_users(user_id_a, user_id_b)
  tags_a = tags_for_user(user_id_a)
  tags_b = tags_for_user(user_id_b)

  count_compare = simple_count_compare(tags_a, tags_b)
  kl_divergence = kl_divergence(tags_a, tags_b)
end
