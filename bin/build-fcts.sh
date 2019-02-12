# Sourced script
# 
# Contains some functions and shared definition to build the code properly

# Those function must be executed from the repo root path.

export TAG_BASE="forjdevops/jenkins"

# Function to identify the Jenkins version to install
#
# $1: Jenkins rule version or Jenkins version
# $2: Database source (redhat or redhat-stable)
function jenkinsVersion() {
    local RULE="$(echo $1 | grep -e "^regexp" | sed 's/^regexp:\(.*\)$/\1/g')"
    if [[  "$RULE" != "" ]]
    then
        SOURCE=$2
        if [[ "$SOURCE" = "" ]]
        then
            SOURCE=redhat
        fi
        # Search for version matching the rule
        export JENKINS_VERSION="$(curl -s https://pkg.jenkins.io/$SOURCE/ | grep -e jenkins-$RULE\.noarch\.rpm | sed 's/^.*jenkins-\('"$RULE"'\)\.noarch.rpm'"'"'.*$/\1/g' | head -n 1)"
    else
        export JENKINS_VERSION=$1
    fi
    echo "Jenkins version $JENKINS_VERSION selected" 1>&2
}

# Function to return 1 if the current code have to be released.
#
# How a release is determined?
# - a release file called release-$RELEASE.md must exist under release-notes/
# - a release tag doesn't exist and declared as release or pre-release (not draft) in github releases - uses github-release command
# - The git branch name must be master. (or BRANCH_NAME=master used by Jenkins)
function isReleaseable() {
    if [[ ! -f release-notes/release-$(getLastVersion).md ]]
    then
        return 1
    fi

    if isMaster 
    then
        return 1
    fi

    local releaseVersion=$(getNewRelease)
    if [[ "$releaseVersion" = "" ]]
    then 
        return 1
    fi
}

# isPreReleaseable return true(0) when the code is 
# Prepared to be released (not in master)
# and the release note is not ready
#
# A release note not ready is the release_<version>.md when the 
# delivery date is > now or not set.
# The delivery date is written as case insensitive:
# "Date: <YYYY/MM/DD>"
#
# it returns true, when the date identified in 
# the release note date is the current or later date
#
function isReleaseMergeable() {
    if ! isReleaseable 
    then
        return 3
    fi

    local releaseDate="$(grep -i -e "date *: *[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9])" release-notes/release-$(getLastVersion).md | sed 's/.*date *: *\([0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9]\).*/\1/gi')"
    if [[ "$releaseDate" = "" ]]
    then
        return 2
    fi
    let diff=(`date +%s`- `date +%s -d $releaseDate` )

    if [[ $diff -gt 0 ]]
    then
        return
    fi
    return 1
}

function isMaster() {
    local branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ $branch != "master" ]] || [[ "$BRANCH_NAME" != master ]]
    then
        return 1
    fi
    return
}

# getReleaseTags return a list of release's tags to build and tag
# The output is a list of lines which contains each 3 fields separated by a |
# a line is a build to execute
# Column 1 : Jenkins Version to build
# Column 2 : List of tags to assign to the build result
# Column 3 : Source of Jenkins packages (redhat/redhat-stable)
#
# This structure is conform to releases.lst file structure, except that Column 1 is the selected Jenkins version
function getReleaseTags() {
    cat releases.lst | while read LINE
    do
        [[ "$LINE" =~ ^# ]] && continue
        local rule=$(echo "$LINE" | awk -F'|' '{ print $1 }')
        local tags=$(echo "$LINE" | awk -F'|' '{ print $2 }')
        local source=$(echo "$LINE" | awk -F'|' '{ print $3 }')
        jenkinsVersion $rule $source

        echo "$JENKINS_VERSION|$tags|$source"
    done
}


# getNewRelease display the New release version.
#
# A new release version is a draft release or unknown release in github
#
function getNewRelease() {
    local version=$(getLastVersion)

    local releaseInfo=$(runGithubRelease info -u forj-oss -r jenkins-ci -t $version --json)
    if [[ $? -eq 0 ]]
    then 
        if [[ "$(echo $releaseInfo | jq '.Releases[0].draft')" = "true" ]]
        then
            echo version
        fi
        return
    fi
    echo version
}

function getLastVersion() {
    if [[ ! -f VERSION ]]
    then
        echo "Unable to determine the release version. Are you in the repo root path?" 1>&2
        return 1
    fi
    cat VERSION | head -n 1
}

function runGithubRelease() {
    if [[ ! -x bin/linux/amd64/github-release ]]
    then
        curl -sL https://github.com/aktau/github-release/releases/download/v0.7.2/linux-amd64-github-release.tar.bz2 | tar -xvjf -
    fi

    bin/linux/amd64/github-release "$@"

}