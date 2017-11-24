#!/bin/bash

PLATFORMS=$(ls $PLATFORMS_DIRECTORY_PATH)
select PLATFORM in $PLATFORMS
do
	export TABRIS_IOS_PLATFORM=$PLATFORMS_DIRECTORY_PATH/$PLATFORM/artifacts/tabris-ios
	eval "$@"
	exit $?
done
