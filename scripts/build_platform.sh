#!/bin/bash

# -----------------------------------------------------------------------------
# REQUIRED ENV VARIABLES (you have to set them before running the script!)
# -----------------------------------------------------------------------------

# `DONT_COPY_REPOSITORIES`
#
# If it's not null repositories will not be copied, but used as they are in
# given directories.


# `PLATFORMS_DIRECTORY_PATH`
#
# Path to the directory where final platform should be stored.


# `TABRIS_IOS_PATH`
#
# Path to the directory with `eclipsesource/tabris-ios` repository


# `CORDOVA_IOS_PATH`
#
# Path to the directory with `eclipsesource/cordova-ios` repository


# `TABRIS_JS_CORDOVA_PATH`
#
# Path to the directory with `eclipsesource/tabris-js-cordova` repository


# -----------------------------------------------------------------------------
# BOOT CODE
# -----------------------------------------------------------------------------

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/vars.sh
PWD=`pwd`

# -----------------------------------------------------------------------------
# SCRIPT
# -----------------------------------------------------------------------------

print_variables PLATFORMS_DIRECTORY_PATH TABRIS_IOS_PATH CORDOVA_IOS_PATH TABRIS_JS_CORDOVA_PATH

# VERIFY INPUT VARIABLES
dir_exists $PLATFORMS_DIRECTORY_PATH
dir_exists $TABRIS_IOS_PATH
dir_exists $CORDOVA_IOS_PATH
dir_exists $TABRIS_JS_CORDOVA_PATH

# PREPARE WORKSPACE AND ENVIRONMENT
readonly JOB_RANDOM_NUMBER=$RANDOM
readonly WORKSPACE_PATH=/tmp/tabris-ios_platform_build_$JOB_RANDOM_NUMBER
readonly LOG_FILE=$WORKSPACE_PATH/internal.stdout
mkdir -p $WORKSPACE_PATH
touch $LOG_FILE
trap exit_trap EXIT

print_info "Workspace directory: \"$WORKSPACE_PATH\"."
print_info "Internal stdout file: \"$LOG_FILE\"."

# GIVE A NICE NAMES TO THE USER INPUT (ARGS)
readonly GIVEN_TABRIS_IOS_REF="$1"
readonly GIVEN_CORDOVA_IOS_REF="$2"
readonly GIVEN_TABRIS_JS_CORDOVA_REF="$3"

# GET COMMIT REFS FOR SPECIFIC REPOSITORIES FROM THE USER
read_commit_ref TABRIS_IOS_REF "$GIVEN_TABRIS_IOS_REF" $TABRIS_IOS_DIRECTORY_NAME $DEFAULT_TABRIS_IOS_REF
read_commit_ref CORDOVA_IOS_REF "$GIVEN_CORDOVA_IOS_REF" $CORDOVA_IOS_DIRECTORY_NAME $DEFAULT_CORDOVA_IOS_REF
read_commit_ref TABRIS_JS_CORDOVA_REF "$GIVEN_TABRIS_JS_CORDOVA_REF" $TABRIS_JS_CORDOVA_DIRECTORY_NAME $DEFAULT_TABRIS_JS_CORDOVA_REF

# COPY GIVEN REPOSITORIES TO THE WORKSPACE IF REQUIRED
if [[ -n $DONT_COPY_REPOSITORIES ]]; then
	print_info "Using repositories as they are - not copying!"
	readonly WORKSPACE_TABRIS_IOS_PATH=$TABRIS_IOS_PATH
	readonly WORKSPACE_CORDOVA_IOS_PATH=$CORDOVA_IOS_PATH
	readonly WORKSPACE_TABRIS_JS_CORDOVA_PATH=$TABRIS_JS_CORDOVA_PATH
else
	print_info "Copying repositories into workspace."
	readonly WORKSPACE_TABRIS_IOS_PATH=${WORKSPACE_PATH}/$TABRIS_IOS_DIRECTORY_NAME
	readonly WORKSPACE_CORDOVA_IOS_PATH=${WORKSPACE_PATH}/$CORDOVA_IOS_DIRECTORY_NAME
	readonly WORKSPACE_TABRIS_JS_CORDOVA_PATH=${WORKSPACE_PATH}/$TABRIS_JS_CORDOVA_DIRECTORY_NAME

	log_and_execute cp -r $TABRIS_IOS_PATH $WORKSPACE_TABRIS_IOS_PATH
	log_and_execute cp -r $CORDOVA_IOS_PATH $WORKSPACE_CORDOVA_IOS_PATH
	log_and_execute cp -r $TABRIS_JS_CORDOVA_PATH $WORKSPACE_TABRIS_JS_CORDOVA_PATH
fi

# PREPARE REPOSITORIES FOR BUILDING THE PLATFORMS
print_info "Checking out repositories into specified commits."
log_and_execute cd $WORKSPACE_TABRIS_IOS_PATH
log_and_execute git stash
log_and_execute git checkout $TABRIS_IOS_REF

log_and_execute cd $WORKSPACE_CORDOVA_IOS_PATH
log_and_execute git stash
log_and_execute git checkout $CORDOVA_IOS_REF

log_and_execute cd $WORKSPACE_TABRIS_JS_CORDOVA_PATH
log_and_execute git stash
log_and_execute git checkout $TABRIS_JS_CORDOVA_REF

# BACKSLASH ESCAPE COMMIT REFS WHEN USING AS A DIRECTORY NAME
# (ex. `task/abc` -> `task-abc`)
readonly BACKSLASH_ESCAPED_TABRIS_IOS_REF=${TABRIS_IOS_REF//\//-}
readonly BACKSLASH_ESCAPED_CORDOVA_IOS_REF=${CORDOVA_IOS_REF//\//-}
readonly BACKSLASH_ESCAPED_TABRIS_JS_CORDOVA_REF=${TABRIS_JS_CORDOVA_REF//\//-}

# CREATING PLATFORM
readonly ORIGINAL_PLATFORM_NAME=tabris-ios-platform_${BACKSLASH_ESCAPED_TABRIS_IOS_REF}_${BACKSLASH_ESCAPED_CORDOVA_IOS_REF}_${BACKSLASH_ESCAPED_TABRIS_JS_CORDOVA_REF}
WORKSPACE_PLATFORM_PATH=$WORKSPACE_PATH/$ORIGINAL_PLATFORM_NAME
print_info "Creating platform in: \"$WORKSPACE_PLATFORM_PATH\"."
log_and_execute mkdir $WORKSPACE_PLATFORM_PATH
log_and_execute cd $WORKSPACE_PLATFORM_PATH

# PREAPRE ENV VARS FOR THE PLATFORM BUILD SCRIPT
export DO_NOT_REMOVE_TABRIS_IOS_REPOSITORY=true
export TABRIS_IOS_PARENT_DIR="${WORKSPACE_TABRIS_IOS_PATH}/.."
export CORDOVA_IOS_PARENT_DIR="${WORKSPACE_CORDOVA_IOS_PATH}/.."
export TABRIS_JS_CORDOVA_PARENT_DIR="${WORKSPACE_TABRIS_JS_CORDOVA_PATH}/.."
log_and_execute ${WORKSPACE_CORDOVA_IOS_PATH}/scripts/build.sh

# COPY PLATFORM TO THE USER DEFINED DIRECTORY
OUTPUT_PLATFORM_NAME=$ORIGINAL_PLATFORM_NAME
print_info "Copying platform to: " $PLATFORMS_DIRECTORY_PATH
if [[ -d "$PLATFORMS_DIRECTORY_PATH/$ORIGINAL_PLATFORM_NAME" ]]; then
	print_info "Directory \"$ORIGINAL_PLATFORM_NAME\" already exists in \"$PLATFORMS_DIRECTORY_PATH\"."
	OUTPUT_PLATFORM_NAME="${ORIGINAL_PLATFORM_NAME}_${JOB_RANDOM_NUMBER}"
	print_info "Platform will be renamed to: \"$OUTPUT_PLATFORM_NAME\"."
	log_and_execute cd ..
	log_and_execute mv $ORIGINAL_PLATFORM_NAME $OUTPUT_PLATFORM_NAME
	WORKSPACE_PLATFORM_PATH=$WORKSPACE_PATH/$OUTPUT_PLATFORM_NAME
fi
log_and_execute cp -r $WORKSPACE_PLATFORM_PATH $PLATFORMS_DIRECTORY_PATH
print_info "Platform is available at:"
echo $PLATFORMS_DIRECTORY_PATH/$OUTPUT_PLATFORM_NAME
