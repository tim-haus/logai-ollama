# LogAI
A simple Ruby script using `ollama-ai` Rubygem.

## Setup
Ensure you have Rubygems Bundler installed.

Run:
Clone repo.
`bundle install` in the directory.
Copy `config.yml.tpl` to `config.yml` and modify accordingly to your preference.
Modify `query_ai.rb` to point to the correct LLM endpoint and log.

## Usage
```
Usage: query_ai.rb --type [journalctl,file] --filepath PATH_IF_FILE_TYPE
    -t, --type TYPE                  Specify a type. Supported: [journalctl, file]
    -f, --file FILEPATH              Specify the file path. Required if --type is set to file.
    -a, --age HOURS                  Specify the age of logs to pull from journalctl. Required if --type is set to journalctl.
    -h, --help                       Prints this dialog.
```

## TODO
The following are what I'd like to do next:

- Externalize configuration to yaml file
- Clean up readme
- Add different types of log types
- Integrate with Jenkins?