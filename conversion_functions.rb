def remove_tag_and_contents(text, tag)
  text.gsub(/<#{tag}[^>]*>[\s\S]*?<\/#{tag}>\n\n/, '')
end

def format_time_from_microseconds(microseconds)
  total_seconds = microseconds / 1000000.0

  minutes = (total_seconds / 60).to_i
  seconds = (total_seconds % 60).to_i
  milliseconds = ((total_seconds % 1) * 1000).to_i
  micro = (microseconds % 1000)

  format("%02d:%02d:%03d.%03d", minutes, seconds, milliseconds, micro)
end