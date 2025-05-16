def ensure_gem(gem_name)
  require gem_name
rescue LoadError
  puts "Installing missing gem: #{gem_name}..."
  system("gem install #{gem_name}") || abort("❌ Failed to install #{gem_name}")
  Gem.clear_paths
  require gem_name
end

ensure_gem 'ollama-ai'
require 'json'
require 'benchmark'
require 'yaml'
require 'optparse'

require_relative 'conversion_functions'

config = YAML.load_file('config.yml')

options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: query_ai.rb --type [journalctl,file] --filepath PATH_IF_FILE_TYPE"

  opts.on("-t", "--type TYPE", "Specify a type. Supported: [journalctl, file]") do |t|
    options[:log_type] = t
  end

  opts.on("-f", "--file FILEPATH", "Specify the file path. Required if --type is set to file.") do |t|
    options[:log_file] = t
  end

  opts.on("-a", "--age HOURS", "Specify the age of logs to pull from journalctl. Required if --type is set to journalctl.") do |t|
    options[:log_age] = t
  end

  opts.on("-s", "--server ADDRESS", "Specify the Ollama server address.") do |s|
    options[:server] = s
  end

  opts.on("-m", "--model MODEL", "Specify the Ollama model name.") do |m|
    options[:model] = m
  end

  opts.on("-h", "--help", "Prints this dialog.") do
    puts opts
    exit
  end
end

begin
  parser.parse!
rescue OptionParser::InvalidOption => e
  puts e.message
  puts parser
  exit 1
end

OLLAMA_SERVER = options[:server] || config['server']
OLLAMA_MODEL = options[:model] || config['model']

# Parameter validation
if options[:log_type].nil?
  puts "Error: --type is required."
  puts parser
  exit 1
elsif (options[:log_file].nil? && options[:log_type] == 'file')
  puts "Error: --file is required if --type is set to file."
  puts parser
  exit 1
elsif (options[:log_age].nil? && options[:log_type] == 'journalctl')
  puts "Error: --age is required if --type is set to journalctl."
  puts parser
  exit 1
end

if OLLAMA_SERVER.nil? || OLLAMA_MODEL.nil?
  puts "Error: Both --server and --model must be specified, either in the command line or config.yml."
  puts parser
  exit 1
end

log_content = ''
case(options[:log_type])
when 'journalctl'
  # Pull journalctl
  log_content = `journalctl --since "#{options[:log_age]} hours ago" --no-pager`
when 'file'
  # Read file for submission.
  log_content = File.read(options[:log_file])
  puts 'Log file loaded.'
else
  exit 'something went wrong'
end

output_variables = {
  TIMESTAMP: Time.now.strftime("%Y%m%d-%H%M%S"),
  LOG_TYPE: options[:log_type]
}

# Output settings
OUTPUT_PATH = config['output']['path']
OUTPUT_FILE = config['output']['file_template'] % output_variables

prompt_variables = {
  TIMESTAMP: Time.now.strftime("%Y%m%d-%H%M%S"),
  LOG_CONTENT: log_content
}

ANALYSIS_PROMPT = config['prompt'] % prompt_variables

puts "Prompt prepared. Connecting to LLM using model #{OLLAMA_MODEL}..."

client = Ollama.new(
  credentials: { address: OLLAMA_SERVER },
  options: { server_sent_events: true }
)

# Validate if the model exists, and install it if it doesn't
model_installed = false
client.tags[0]['models'].each do |tag|
  if tag['model'] == OLLAMA_MODEL
    model_installed = true
    break
  else
    model_installed = false
  end
end

if model_installed == false
  puts "Model #{OLLAMA_MODEL} not found on server. Pulling..."
  client.pull( {model: OLLAMA_MODEL }) do |event,raw|
    if event['status'] == 'success'
      puts "Model #{OLLAMA_MODEL} has been downloaded."
    end
  end
else
  puts "Model #{OLLAMA_MODEL} exists. Continuing."
end

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