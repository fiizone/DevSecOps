#!/usr/bin/env ruby
require 'json'

# Path to the error codes file
ERROR_CODES_FILE = "/etc/fluentd/error_codes.json"

# Load error codes
def load_error_codes
  begin
    file_content = File.read(ERROR_CODES_FILE)
    JSON.parse(file_content)
  rescue StandardError => e
    STDERR.puts "Error loading error codes: #{e.message}"
    {}
  end
end

ERROR_CODES = load_error_codes

# Read from STDIN and process each log line
ARGF.each_line do |line|
  begin
    record = JSON.parse(line.strip)

    # Extract error code from structured logs
    if record["error_code"]
      err_code = record["error_code"]
      record["error_code_message"] = ERROR_CODES[err_code] || "Unknown error"

    # Extract error code from plain-text logs using regex
    elsif record["log"] && (match = record["log"].match(/(ERR\d{3})/))
      err_code = match[1]
      record["error_code"] = err_code
      record["error_code_message"] = ERROR_CODES[err_code] || "Unknown error"
    end

    # Output the enriched log
    puts record.to_json

  rescue JSON::ParserError => e
    STDERR.puts "JSON parse error: #{e.message}, input: #{line.strip}"
  end
end
 
