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


createAuthorsFile
checkoutGitSVN
migrateTags
migrateBranches
