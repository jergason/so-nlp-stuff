require './downloader'

# Simple measure of difference between users
# by comparing presence and absence of tags.
def simple_count_compare(tags_a, tags_b)
  all_words = tags_a.keys.concat(tags_b.keys).uniq
  common = 0
  different = 0
  all_words.each do |word|
    if tags_a[word] == tags_b[word]
      common += 1
    else
      different += 1
    end
  end

  common.to_f / (common.to_f + different.to_f)
end

# Given two Hashses of :key => probabilty,
# calculate the KL-divergence of the two
def kl_from_probability_distributions(p_a, p_b)
  p_a.inject(0.0) do |sum, values|
    if p_b[values[0]] == 0 || values[1] == 0
      sum
    else
      sum + (values[1] * Math.log(values[1].to_f / p_b[values[0]]))
    end
  end
end

# Compare to distributions of tags using the kl-divergence (http://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence)
# metric. Since it is not symmetrical, we calculate it both ways.
#
# This is a more complex comparison because it takes in to account
# the number of tags.
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

  [kl_a, kl_b]
end

def tags_for_user(user_id, downloader)
  tags = downloader.get_tags(user_id)
  return_tags = {}
  tags.each do |tag|
    return_tags[tag['name']] = tag['count']
  end

  return_tags
end

def compare_users(user_id_a, user_id_b, downloader)
  tags_a = tags_for_user(user_id_a, downloader)
  tags_b = tags_for_user(user_id_b, downloader)

  count_compare = simple_count_compare(tags_a, tags_b)
  kl_divergence = kl_divergence(tags_a, tags_b)

  [count_compare, kl_divergence]
end


downloader = Downloader.new

puts compare_users(ARGV[0], ARGV[1], downloader)
