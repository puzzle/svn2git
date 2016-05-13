#!/bin/bash -x
: ${SVN_REPOSITORY:?"SVN_REPOSITORY is required"}
: ${PROJECT:?"PROJECT is required"}

: ${WORKDIR:=$(mktemp -d -t svn2git."$PROJECT".XXXXX)}
: ${AUTHORS_FILE:="$WORKDIR/authors"}
: ${MIGRATE_DIR:="$WORKDIR/migration"}

: ${AUTHORS_PATTERN:='$1 <$1>'}

function createAuthorsFile {
    svn log --xml "$SVN_REPOSITORY" | grep author | perl -pe "s/.*>(.*?)<.*/\$1 = $AUTHORS_PATTERN/" | sort -u > "$AUTHORS_FILE"
}

function checkoutGitSVN {
    #TODO sr - add flag for skipping metadata
    #TODO sr - add flags for non-standard layouts
    git svn clone "$SVN_REPOSITORY" --stdlayout --prefix=svn/ --authors-file="$AUTHORS_FILE" -s "$MIGRATE_DIR"
}

createAuthorsFile
checkoutGitSVN
