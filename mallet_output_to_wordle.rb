def mallet_output_to_wordle(mallet_file_name)
  lines = IO.readlines(mallet_file_name)

  parsed_output_string = ""

  lines.each do |line|
    fields = line.gsub("\t", " ").strip.split(" ")[2..-1].reverse
    counter = 1
    result = fields.inject("") do |res, field|
      res << "#{field}:#{counter}\n"
      counter += 1
      res
    end

    result = result << "\n\n\n"
    parsed_output_string << result
  end

  parsed_output_string
end

puts "argv is #{ARGV}"
puts mallet_output_to_wordle(ARGV[0])
