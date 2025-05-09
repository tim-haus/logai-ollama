server: http://192.168.0.60:11434
model: granite3.3:8b

# Allowed variables for output (contain within %{}):
# LOG_TYPE: Type of log [journalctl, file]
# TIMESTAMP: Current timestamp of generated file
output:
  path: ./output
  file_template: log_%{LOG_TYPE}_%{TIMESTAMP}

# Allowed variables for prompt (contain within %{}):
# LOG_CONTENT: contents of the log parsed based on file definition. Only works in prompt.
prompt: |
  You are a helpful IT assistant. Based on the below log, can you call out any WARNING, ERROR, CRITICAL, or FATAL log entries with their timestamp in PST, and give a brief synopsis of what that log calls out. If there are none that match this, let the user know and don't worry about the synopsis.
  
  Then, can you summarize the most concerning log entries, if any, and provide specifically the entries and their line numbers? Call out specifically any WARNING, ERROR, CRITICAL, or FATAL errors immediately, with appropriate emphasis given to the severity of these entries. Give specific recommendations on remediations where possible. Make a brief synopsis of the overall status of the logs, especially if there's nothing to be concerned about.

  Finally, conclude with a brief synopsis of the findings and call out if there's anything to be concerned about or not.
  
  Use only plaintext for formatting. Do not use any Markdown. Remember to treat the user as a professional with a higher than average understanding of the subject matter.
  
  Here's the log contents:
  %{LOG_CONTENT}