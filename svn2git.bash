#!/bin/bash

function usage {
    cat << EOF
Usage: $0 <parameters>

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
        $ $0 -p myproject -s svn://myproject.code.svn -g ssh://git@myproject.code.git
            Migrates 'myproject' from 'svn://myproject.code.svn' to 'ssh://git@myproject.code.git'

Optional parameters:

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
    #TODO sr - add flags for non-standard layouts
    git svn clone "$SVN_REPOSITORY" $NO_METADATA_FLAG --stdlayout --prefix=svn/ --authors-file="$AUTHORS_FILE" -s "$MIGRATE_DIR"
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

params="$(getopt -o p:sghv -l project:,svn,git,help,verbose,no-metadata --name "$(basename -- "$0")" -- "$@")"
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


: ${PROJECT:?"PROJECT is required"}
: ${SVN_REPOSITORY:?"SVN_REPOSITORY is required"}
: ${GIT_REPOSITORY:?"GIT_REPOSITORY is required"}

: ${WORKDIR:=$(mktemp -d -t svn2git."$PROJECT".XXXXX)}
: ${AUTHORS_FILE:="$WORKDIR/authors"}
: ${MIGRATE_DIR:="$WORKDIR/migration"}
: ${BARE_DIR:="$WORKDIR/${PROJECT}-bare.git"}

: ${AUTHORS_PATTERN:='$1 <$1>'}
: ${NO_METADATA_FLAG:=""}


createAuthorsFile
checkoutGitSVN
migrateTags
migrateBranches
migrateIgnoredFiles
cloneBare
pushBareClone

#TODO sr cleanup
