#!/bin/bash
set -x
# -----------------------------------------------------------------------------
# BOOT CODE
# -----------------------------------------------------------------------------

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/vars.sh
PWD=$(pwd)

readonly SECURE_CONFIG_FILENAME=secureConfig.json
readonly ARTIFACTS_DIR=$PWD/artifacts

if [ -d $ARTIFACTS_DIR ]; then
	print_info '"artifacts" directory already exists'
	exit 1
fi

log_and_execute mkdir $ARTIFACTS_DIR

# "true" or "false"
# DO_NOT_REMOVE_TABRIS_IOS_REPOSITORY=true

# path to directories containing specific repos (without trailing slashes!)
# TABRIS_IOS_PARENT_DIR=/Users/foo/eclipsesource
# CORDOVA_IOS_PARENT_DIR=/Users/foo/eclipsesource
# TABRIS_JS_CORDOVA_PARENT_DIR=/Users/foo/eclipsesource

dir_exists $TABRIS_IOS_PARENT_DIR/tabris-ios
dir_exists $CORDOVA_IOS_PARENT_DIR/cordova-ios
dir_exists $TABRIS_JS_CORDOVA_PARENT_DIR/tabris-js-cordova

# prepare tabris-ios security
if [ X"$SECURE_BUILD" = X"true" ]; then
	echo $PUBLIC_KEY > tabris-ios.rsa.pub.key
	PUBLIC_KEY=$PWD/tabris-ios.rsa.pub.key

	export AES_KEY=$AES_KEY
	export AES_IV=$AES_IV
	export PUBLIC_KEY=$PUBLIC_KEY

	log_and_execute $DIR/store_secure_constants.sh

	log_and_execute rm $PUBLIC_KEY
fi

# build tabris-js-cordova
if [ ! -f "$TABRIS_JS_CORDOVA_PARENT_DIR/tabris-js-cordova/build/cordova.ios.js" ]; then
	export TABRIS_JS_CORDOVA_NO_ANDROID="true"
	export TABRIS_JS_CORDOVA_NO_WINDOWS="true"
	log_and_execute cd $TABRIS_JS_CORDOVA_PARENT_DIR/tabris-js-cordova
	log_execution ./build.sh
	exit_if_command_fail ./build.sh
fi

# mkdir artifacts
log_and_execute cd $PWD

# copy cordova-ios
log_and_execute cp -R $CORDOVA_IOS_PARENT_DIR/cordova-ios $ARTIFACTS_DIR/tabris-ios

# store tabris-ios secure constants in encrypted file
if [ X"$SECURE_BUILD" = X"true" ]; then
	echo "{ \"key\":\"$AES_KEY\", \"iv\":\"$AES_IV\" }" > $ARTIFACTS_DIR/tabris-ios/$SECURE_CONFIG_FILENAME
fi

# copy tabris-js-cordova artifacts to cordova-ios platform
log_and_execute cp $TABRIS_JS_CORDOVA_PARENT_DIR/tabris-js-cordova/build/cordova.ios.js $ARTIFACTS_DIR/tabris-ios/CordovaLib/cordova.js
log_and_execute cp $TABRIS_JS_CORDOVA_PARENT_DIR/tabris-js-cordova/src/exec-ios.js $ARTIFACTS_DIR/tabris-ios/cordova-js-src/exec.js
log_and_execute cp $TABRIS_JS_CORDOVA_PARENT_DIR/tabris-js-cordova/src/platform-ios.js $ARTIFACTS_DIR/tabris-ios/cordova-js-src/platform.js

# store Tabris.js version in text file
TABRIS_FRAMEWORK_INFO_PLIST="$TABRIS_IOS_PARENT_DIR/tabris-ios/Tabris/Tabris/Info.plist"
if [ -d "$TABRIS_IOS_PARENT_DIR/tabris-ios/artifacts/Release-fat/Tabris.framework" ]; then
	# when framework was already compiled, sources (and Info.plist) are not available
	# in this case we read Info.plist from the compiled framework
	TABRIS_FRAMEWORK_INFO_PLIST="$TABRIS_IOS_PARENT_DIR/tabris-ios/artifacts/Release-fat/Tabris.framework/Info.plist"
fi
TABRIS_VERSION=$(xmllint --xpath "/plist/dict/key[.='ESTabrisPlatformVersionString']/following-sibling::string[1]/text()" $TABRIS_FRAMEWORK_INFO_PLIST)
echo $TABRIS_VERSION > $ARTIFACTS_DIR/tabris-ios/TABRIS_IOS_VERSION

# create artifact for archive
log_and_execute cd $ARTIFACTS_DIR
log_and_execute zip \
	--exclude \
		.travis.yml \
		*.git* \
		.gitignore \
		tabris-ios/scripts* \
	--recurse-paths \
	tabris-ios.zip \
	tabris-ios

if [ X"$SECURE_BUILD" = X"true" ]; then
	# ${VARNAME:-word} if VARNAME exists and isn't null return it's value, otherwise return word
	log_and_execute mv tabris-ios.zip tabris-ios-$TABRIS_VERSION-${CLIENT_ID:-com.example.undefined.client.id}.zip
fi
