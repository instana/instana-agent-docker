#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] -t template.txt.tmpl output.txt

Script to apply templating to a given input file

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-t, --template  The template file
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  template=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -t | --template) # example named parameter
      template="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  [[ -z "${template-}" ]] && die "Missing required parameter: template"
  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

check_if_template_exists() {
  if [ ! -f $template ]
  then
      msg "${RED}ERROR: file $template does not exist.${NOFORMAT}"
      exit 1
  fi
}


evaluate_template() {
    local input_file="$1"
    local output_file="$2"

    perl -ne "$(cat <<'EOF'
        # Function to replace {{ getenv "KEY" }} and {{ getenv "KEY" "default" }} in a line
        sub replace_getenv {
            my ($line) = @_;
            my $replacement = "";

            # Loop to find all occurrences of {{ getenv "KEY" }} or {{ getenv "KEY" "default" }}
            while ($line =~ /\{\{\s*getenv\s*"([^"]+)"(?:\s*"([^"]*)")?\s*\}\}/) {
                my $key = $1;
                my $default_value = $2;

                # Bash command substitution to get the value of the environment variable
                my $env_value = qx(test -n "\$$key" && echo -n "\$$key");
                chomp($env_value);  # Remove newline characters

                # Check if the environment variable is defined and not empty
                $replacement = defined $env_value && $env_value ne "" ? $env_value : (defined $default_value ? $default_value : "");

                # Replace the matched substring with the calculated replacement
                $line =~ s/\{\{\s*getenv\s*"$key"\s*(?:\s*"$default_value")?\s*\}\}/$replacement/;
            }

            return $line;
        }

        # Initialize variables
        BEGIN { $in_block = 1; @in_block_stack = (); }
        
        # Function to check if a variable is defined and not empty within an if block
        sub check_in_block {
            my ($variable, $in_block_outer) = @_;
            my $env_value = qx(test -n "\$$variable" && echo -n "\$$variable");
            chomp($env_value);

            # Set $in_block to true if the variable is defined, not empty, and $in_block_outer is true
            my $in_block = defined $env_value && $env_value ne "" && $in_block_outer;
            
            # Push the current $in_block state onto the stack
            push @in_block_stack, $in_block;

            return $in_block;
        }

        # Function to pop the last value from the in_block stack
        sub pop_in_block {
            pop @in_block_stack;
            
            # Return true if the stack is empty or the last value on the stack is true
            return !@in_block_stack || $in_block_stack[-1];
        }

        # Main processing loop
        if (/^\s*\{\{-?\s*if\s*getenv\s*"([^"]+)"\s*}}\s*$/) {
            # Handle the start of an if block
            $variable = $1;
            $in_block = check_in_block($variable, $in_block);
        } elsif (/^\s*\{\{-?\s*else\s*}}\s*$/) {
            # Handle the else part of an if block
            $in_block = !$in_block;
        } elsif (/^\s*\{\{-?\s*end\s*}}\s*$/) {
            # Handle the end of an if block
            $in_block = pop_in_block();
        } elsif ($in_block) {
            # Handle replacements for lines of an active if block and outside if blocks
            $line = replace_getenv($_);
            print $line;
        }
EOF
)" "$input_file" > "$output_file"
}


parse_params "$@"
setup_colors
check_if_template_exists
evaluate_template ${template} "${args[0]}"