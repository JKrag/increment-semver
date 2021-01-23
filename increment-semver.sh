#!/usr/bin/env bash

# The purpose of this script is to generate a continuously increasing SemVer type version number
# for a project, by leveraging the hosted service http://increment.build.(1)
# It provides a very good alternative for using "build id" numbers from your CI server as
# part of your version number, which for many reasons is a bad practice. (e.g. there is typically
# no way to "reset" build-id to zero when you bump a minor or major version. Also, at least on
# Azure DevOps, the BuildId sequence is shared among all pipelines in a project, which can make for some
# very rapidly increasing numbers).
# It its current form, this script assumes that major.minor versions are managed elsewhere,
# and passed in as arguments to this script.
# This script then generates(2) a full major.minor.patch version number, using the next unused
# available patch number delivered by the increment.build service.

# 1) If you don't want to use the publicly hosted service,you can choose to run your own copy,
# on premise or on a cloud of choice, as the increment.build project is Open Source under a MIT license
#
# 2) In its current form, this script is designed for use in Azure Devops, but the only concession
# to this usage is that the script outputs the result as a console "##vso[task.setvariable ...]"
# statement for use in later build stages instead of returning the value. The name of the variable
# being set is 'tag', as it is currently used mainly to tag docker images.


usage() {
  echo "Usage: $0 -p <PROJECT_NAME> -v <PROJECT_VARIANT> -m <MAJOR_VERSION> -n <MINOR_VERSION>"
  echo "Note: If this is the main product version, i.e. not a PROJECT_VARIANT, set -v to '' or leave it out."
  echo
  echo "Example: $0 -p \"my-app\" -v \"sandbox-\" -m 2 -n 0"
  echo
  echo "The 4 arguments together will make up the identifier used to "
  echo "to retrieve the next patch version from http://increment.build."
  echo "For the purpose of anonymization, the identifier is hashed and we use"
  echo "the hash as a token. By including major.minor in the string, we automatically"
  echo "get a new sequence from 0 when ever we bump a major or minor".
  exit 1;
}

while getopts p:v:m:n:h option; do
  case "${option}"
    in
      p) PROJECT=${OPTARG};;
      v) PROJECT_VARIANT=${OPTARG};;
      m) MAJOR=${OPTARG};;
      n) MINOR=${OPTARG};;
      h) usage;;
      *) usage;;
  esac
done

PROJECT_VARIANT="${PROJECT_VARIANT:+$PROJECT_VARIANT-}"  # If PROJECT_VARIANT is not empty, then append a dash separator

VERSIONING_IDENTIFIER="$PROJECT-$PROJECT_VARIANT$MAJOR.$MINOR"

# set -x # Print a trace of commands
set -e # Exit on failed commands

echo "Inc string: $VERSIONING_IDENTIFIER"
increment_build_token=$(echo -n "$VERSIONING_IDENTIFIER" | sha1sum -t | head -c 40)

echo "Inc token: $increment_build_token"
patch=$(curl -s "https://increment.build/$increment_build_token")

# Check that returned value is indeed a number. This protects against
# gibberish or tmp error messages being erroneously used as a version number.
# It also works as a paranoid safety check against attempts at malicious
# code injection.
re='^[0-9]+$'
if ! [[ $patch =~ $re ]] ; then
  echo "error: Not a number" >&2; exit 1
fi

echo "------------------"
echo "Current version number: $MAJOR.$MINOR.$patch"
echo "------------------"
echo "##vso[task.setvariable variable=tag;isOutput=true]$MAJOR.$MINOR.$patch"
echo "------------------"
# echo "Now incrementing patch level version number for future runs"
future=$(curl -s "https://increment.build/$increment_build_token")
echo "Next version will be $MAJOR.$MINOR.$future"