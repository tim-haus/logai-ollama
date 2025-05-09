require 'ollama-ai'
require 'json'
require 'benchmark'
require 'yaml'
require 'optparse'

require_relative 'conversion_functions'

config = YAML.load_file('config.yml')

OLLAMA_SERVER = config['server']
OLLAMA_MODEL = config['model']

# Types: journalctl, file
LOG_TYPE = 'file'

# Only if LOG_TYPE = 'file'
LOG_FILE = '/Users/timhosey/Downloads/journalctl.txt'

# Only if LOG_TYPE = 'journalctl'
# Number of hours back to pull logs
# TODO: Needs to be externalized somehow
LOG_JOURNAL_AGE_HRS = 24

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: query_ai.rb --type [journalctl,file] --filepath PATH_IF_FILE_TYPE"
  opts.on("--type TYPE", "Specify a type. Supported: [journalctl, file]") do |t|
    options[:type] = t
  end

  opts.on("-h", "--help", "Prints this dialog.") do
    puts opts
    exit
  end
end.parse!

# Get timestamp for output naming
current_timestamp = Time.now.strftime("%Y%m%d-%H%M%S")

# Output settings
OUTPUT_PATH = config['output']['path']
OUTPUT_FILE = "log_#{LOG_TYPE}_#{current_timestamp}"

case(LOG_TYPE)
when 'journalctl'
  # Pull journalctl
  log_content = `journalctl --since "#{LOG_JOURNAL_AGE_HRS} hours ago" --no-pager`
when 'file'
  # Read file for submission.
  log_content = File.read(LOG_FILE)
  puts 'Log file loaded.'
else
  exit 'something went wrong'
end

ANALYSIS_PROMPT = <<~PROMPT
  You are a helpful IT assistant. Based on the below log, can you call out any WARNING, ERROR, CRITICAL, or FATAL log entries with their timestamp in PST, and give a brief synopsis of what that log calls out. If there are none that match this, let the user know and don't worry about the synopsis.
  
  Then, can you summarize the most concerning log entries, if any, and provide specifically the entries and their line numbers? Call out specifically any WARNING, ERROR, CRITICAL, or FATAL errors immediately, with appropriate emphasis given to the severity of these entries. Give specific recommendations on remediations where possible. Make a brief synopsis of the overall status of the logs, especially if there's nothing to be concerned about.
  
  Use only plaintext for formatting. Remember to treat the user as a professional with a higher than average understanding of the subject matter.
  
  Here's the log contents:
  #{log_content}
PROMPT

puts "Prompt prepared. Connecting to LLM using model #{OLLAMA_MODEL}..."


client = Ollama.new(
  credentials: { address: OLLAMA_SERVER },
  options: { server_sent_events: true }
)


puts 'Connected. Submitting log to LLM for analysis. Waiting while LLM is processing...'

result = ''
process_time = Benchmark.realtime do
  result = client.generate(
    { model: OLLAMA_MODEL,
      prompt: ANALYSIS_PROMPT,
      stream: false }
  )
end

puts "Completed in #{process_time.round(3)} seconds."

output_content = remove_tag_and_contents(result[0]['response'], 'think')

# We strip out the think tag since it's worthless to what we want sent back to us.
puts "\nRESPONSE:\n\n"
puts output_content
puts "\n"

Dir.mkdir(OUTPUT_PATH) unless Dir.exist?(OUTPUT_PATH)
File.write("#{OUTPUT_PATH}/#{OUTPUT_FILE}", output_content)
puts "Complete. Log saved to #{OUTPUT_PATH}/#{OUTPUT_FILE}."