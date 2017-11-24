#!/bin/bash

# -----------------------------------------------------------------------------
# DEBUGGING
# -----------------------------------------------------------------------------

# print a trace of simple commands when DEBUG variable exists
if [ -n "$DEBUG" ]; then
  set -x
fi

# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------

# make it awesome with colors! :]
# check if stdout is a terminal...
if test -t 1; then
    # see if it supports colors...
    ncolors=$(tput colors)
    if test -n "$ncolors" && test $ncolors -ge 8; then
        bold="$(tput bold)"
        underline="$(tput smul)"
        standout="$(tput smso)"
        normal="$(tput sgr0)"
        black="$(tput setaf 0)"
        red="$(tput setaf 1)"
        green="$(tput setaf 2)"
        yellow="$(tput setaf 3)"
        blue="$(tput setaf 4)"
        magenta="$(tput setaf 5)"
        cyan="$(tput setaf 6)"
        white="$(tput setaf 7)"
    fi
fi

# Print all arguments prefixed with date, use it instead of echo
function print_info {
  echo "${green}[$(date)]${normal}: $@"
}

# Print in the console command which will be executed
function log_execution {
  echo "${blue}[$(date)]${normal}: $@"
}

# This function takes a command to execute as argument. Before executing
# it will be echoed in the console and logged in the $LOG_FILE. Additionally
# stdout with stderr are redirected to the $LOG_FILE.
function log_and_execute {
  unset LOG_AND_EXECUTE_PIPESTATUS
  log_execution "$@"
  if [[ -n $LOG_FILE ]]; then
    echo "\$ $@" >> $LOG_FILE
    $@ 2>&1 >> $LOG_FILE
  else
    eval $@ '; LOG_AND_EXECUTE_PIPESTATUS=(${PIPESTATUS[@]})'
  fi
}

# This function should be used as a exit trap: `trap exit_trap EXIT`
# It will print a message pointing user to the $LOG_FILE for crash
# details. Message will appear only if script exit with non 0 code.
function exit_trap {
	if [[ "$?" -ne 0 ]]; then
		print_info "This script failed to complete, please read $LOG_FILE for details."
	fi
}

# This function verify if "$1" directory exists. If not prints a message and
# exit the script.
function dir_exists {
	if [ ! -d $1 ]
	then
		print_info \"$1\" "directory does not exist"
		exit 1
	fi
}

# Multiple times in this script user is being asked for the commit reference for
# the specified repository, this function handle this question.
#	$1 - Name of the variable where (by "reference") commit ref should be
#		 returned.
#	$2 - If this arg is not null it will be used as a return value and user will
#		 not be asked for the input. You can pass value from environment
#		 variable here.
#	$3 - Name of the repository, it will be presented to the user.
#	$4 - Default value - will be used if user press enter without typing
#		 anything.
#
function read_commit_ref {
	if [[ -n $2 ]]; then
		REF=$2
	else
		print_info "Please provide reference to the commit in \"$3\" repo [$4]:"
		read REF
	fi
	print_info "Using \"$3\" ref: \"${REF:=$4}\"."
	eval $1=$REF
}

# Takes a list of variable names as argument and log their values in the stdout.
function print_variables {
  for VAR in $@ ; do
    echo "${cyan}[$(date)]${normal}: $VAR=${!VAR}"
  done
}

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------

readonly TABRIS_IOS_DIRECTORY_NAME="tabris-ios"
readonly CORDOVA_IOS_DIRECTORY_NAME="cordova-ios"
readonly TABRIS_JS_CORDOVA_DIRECTORY_NAME="tabris-js-cordova"

readonly DEFAULT_TABRIS_IOS_REF="master"
readonly DEFAULT_CORDOVA_IOS_REF="master-development"
readonly DEFAULT_TABRIS_JS_CORDOVA_REF="master"