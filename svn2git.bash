#!/bin/bash

#########################################################################
#                                                                       #
# SVN2Git - a script to ease migration from Subversion to Git           #
#                                                                       #
# Copyright 2016 Stefan Rotman - Puzzle ITC GmbH <rotman@puzzle.ch>     #
#                                                                       #
#########################################################################
#                                                                       #
# This program is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by  #
# the Free Software Foundation, either version 3 of the License, or     #
# (at your option) any later version.                                   #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program.  If not, see <http://www.gnu.org/licenses/>. #
#                                                                       #
#########################################################################

#---------------------
# function definitions 
#---------------------
function usage {
    PROGRAM=$(basename $0)
    cat << EOF
Usage: $PROGRAM <parameters>

Required parameters:

    -p <projectname>
    --project=<projectname>
	Sets the name of the project to migrate.
        This becomes optional if the 'PROJECT" environment variable has been set.

    -s <svn repository>
    --svn=<svn repository>
	Sets the Subversion Repository URL. Important is that this points to the root of the Subversion
        repository, so trunk, tags and branches are accessible
        This becomes optional if the 'SVN_REPOSITORY" environment variable has been set.

    -g <git repository>
    --git=<sgit repository>
	Sets the Git Repository URL. This repository should exist and be empty.
        This becomes optional if the 'GIT_REPOSITORY" environment variable has been set.

    Example:
        $ $PROGRAM -p myproject -s svn://myproject.code.svn -g ssh://git@myproject.code.git
            Migrates 'myproject' from 'svn://myproject.code.svn' to 'ssh://git@myproject.code.git'

Optional parameters:

    -T <dir>
    --trunk=<dir>
        The trunk of the SVN repository (relative to the root)

    -b <dir>
    --branches=<dir>
        A branches subdirectory of the SVN repository (relative to the root). Can occur multiple times.

    -t <dir>
    --tags=<dir>
        A tags subdirectory of the SVN repository (relative to the root). Can occur multiple times.

    --no-metadata
        Don't keep the reference to the original SVN revision in the migrated Git repository

    -v
    --verbose
        Run in verbose mode

    -h
    --help
        Print this message and exit

EOF
   exit
}

function createAuthorsFile {
    svn log --xml "$SVN_REPOSITORY" | grep author | perl -pe "s/.*>(.*?)<.*/\$1 = $AUTHORS_PATTERN/" | sort -u > "$AUTHORS_FILE"
}

function checkoutGitSVN {
    LAYOUT="${TRUNK_FLAG}${BRANCHES_FLAG}${TAGS_FLAG}"
    : ${LAYOUT:="--stdlayout"}

    #TODO sr: check that either stdlayout or trunk exists

    git svn clone "$SVN_REPOSITORY" $NO_METADATA_FLAG $LAYOUT --prefix=svn/ --authors-file="$AUTHORS_FILE" -s "$MIGRATE_DIR"
}

function migrateTags {
    cd "$MIGRATE_DIR"
    git for-each-ref refs/remotes/svn/tags | cut -d / -f 5- |
    while read ref
    do
        git tag -a "$ref" -m "Convert $ref from SVN to Git" "refs/remotes/svn/tags/$ref"
    done
}

function migrateBranches {
    cd "$MIGRATE_DIR"
    git for-each-ref refs/remotes/svn/ | grep -v svn/tags/ | cut -d / -f 4- |
    while read ref
    do
        git branch "$ref" "refs/remotes/svn/$ref"
    done
    git branch -d trunk
}

function migrateIgnoredFiles {
    cd "$MIGRATE_DIR"
    git svn create-ignore
    git commit --author="SVN 2 Git Migration <svn2git>" -m "Migrate svn:ignore to .gitignore" .gitignore

}

function cloneBare {
    git clone --bare "$MIGRATE_DIR" "$BARE_DIR"
}

function pushBareClone {
    cd "$BARE_DIR"
    git remote add gitremote "$GIT_REPOSITORY"
    git push gitremote --all
    git push gitremote --tags
}

function cleanup {
    rm -rf "$WORKDIR"
}

#---------------------
# parameter processing
#---------------------

params="$(getopt -o p:sghvtbT -l project:,svn,git,help,verbose,trunk,branches,tags,no-metadata --name "$(basename -- "$0")" -- "$@")"
if [ $? -ne 0 ]
then
    usage
fi

eval set -- "$params"
unset params

while true
do
    case $1 in
        -p|--project)
          PROJECT=$2
          shift 2
          ;;
        -s|--svn)
          SVN_REPOSITORY=$2
          shift 2
          ;;
        -g|--git)
          GIT_REPOSITORY=$2
          shift 2
          ;;
        -h|--help)
	  usage
          shift
          ;;
        -v|--verbose)
	  VERBOSE="VERBOSE"
          shift
          ;;
        --no-metadata)
	  NO_METADATA_FLAG="--no-metadata"
          shift
          ;;
        -T|--trunk)
          TRUNK_FLAG="-T $2"
          shift 2
          ;;
        -b|--branches)
          BRANCHES_FLAG+=" -b $2"
          shift 2
          ;;
        -t|--tags)
          TAGS_FLAG+=" -t $2"
          shift 2
          ;;
        --)
          shift
          break
          ;;
        *)
          usage
          ;;
    esac
done
if [ "$VERBOSE" == "VERBOSE" ] ; then set -x ; fi

#--------------------
# variable processing
#--------------------

: ${PROJECT:?"PROJECT is required"}
: ${SVN_REPOSITORY:?"SVN_REPOSITORY is required"}
: ${GIT_REPOSITORY:?"GIT_REPOSITORY is required"}

: ${WORKDIR:=$(mktemp -d -t svn2git."$PROJECT".XXXXX)}
: ${AUTHORS_FILE:="$WORKDIR/authors"}
: ${MIGRATE_DIR:="$WORKDIR/migration"}
: ${BARE_DIR:="$WORKDIR/${PROJECT}-bare.git"}

: ${AUTHORS_PATTERN:='$1 <$1>'}
: ${NO_METADATA_FLAG:=""}

: ${TRUNK_FLAG:=""}
: ${BRANCHES_FLAG:=""}
: ${TAGS_FLAG:=""}

#------------------------
# main routine processing
#------------------------
createAuthorsFile
checkoutGitSVN
migrateTags
migrateBranches
migrateIgnoredFiles
cloneBare
pushBareClone
cleanup
