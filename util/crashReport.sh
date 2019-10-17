#!/bin/bash

# TODO
# remove 'logging' echo statements

# Variables for script usage
FILE_HS_ERR_LOG=/opt/instana/agent/hs_err.log
DIR_AGENT_LOG=/opt/instana/agent/data/log
AGENT_LOG_COLLECT_LINES=1000

# Variables for use in the JSON payload
JSON_HOSTNAME="$(hostname)"
JSON_TIMESTAMP="$(date +%s)000"
JSON_PID="${1}"
if [ "${2}" != "" ]; then
  JSON_ERROR="${2}"
else
  JSON_ERROR="Unknown reason for Agent crash"
fi


post_crash_data() {
  echo
  echo $(generate_crash_data)
  echo
  # Silence all output so it doesn't show up in e.g. Docker or Kubernetes logs
  curl -XPOST "https://${INSTANA_AGENT_ENDPOINT}:${INSTANA_AGENT_ENDPOINT_PORT}/metrics" \
    --silent \
	--http2-prior-knowledge \
	--header "x-instana-key: ${INSTANA_AGENT_KEY}" \
	--header "x-instana-host: ${JSON_HOSTNAME}" \
	--header "Content-Type: application/json" \
	--data "$(generate_crash_data)" \
    --output /dev/null 2>&1
  }

#
# Generates the JSON data for sending the crash report. Expects the following variables set:
# - JSON_HOSTNAME: the hostname where the agent runs
# - JSON_TIMESTAMP: timestamp when crash occurred
# - JSON_PID: PID of the crashed Agent
# - JSON_ERROR: the description of the error
# - JSON_LOGS: Last log-lines captured from the agent
#
generate_crash_data() {
  cat <<-EOF
{
  "plugins": [
	{
	  "name": "com.instana.agent",
	  "hostId": "${JSON_HOSTNAME}",
	  "entityId": "self",
	  "data": {
		"crashReport": {
		  "timestamp": ${JSON_TIMESTAMP},
		  "pid": "${JSON_PID}",
		  "error": "${JSON_ERROR}",
		  "logs": {
			"hs_err_log": $(cat_file "${FILE_HS_ERR_LOG}" | format_to_json),
			"agent_log": $(join_sort_dir "${DIR_AGENT_LOG}" | format_to_json)
		  }
		}
	  }
	}
  ]
}
EOF

}

# Expects a directory as parameter, as contents inside are merged and sorted on timestamp and cat to stdout
join_sort_dir() {
  sort -m "$1"/* | tail -n ${AGENT_LOG_COLLECT_LINES} -
}

# Expects just a single file as parameter that will be cat to stdout, but with some handling for when
# the file doesn't exist
cat_file() {
  # Dismiss any error output, which results in the empty string being returned.
  # Another possibility is to redirect error to stdin so the warning shows up for the file.
  cat "$1" 2>/dev/null
}

format_to_json() {
  python -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

post_crash_data
