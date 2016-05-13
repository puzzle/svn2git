#!/bin/bash -x
: ${SVN_REPOSITORY:?"SVN_REPOSITORY is required"}
: ${PROJECT:?"PROJECT is required"}
: ${GIT_REPOSITORY:?"GIT_REPOSITORY is required"}

: ${WORKDIR:=$(mktemp -d -t svn2git."$PROJECT".XXXXX)}
: ${AUTHORS_FILE:="$WORKDIR/authors"}
: ${MIGRATE_DIR:="$WORKDIR/migration"}
: ${BARE_DIR:="$WORKDIR/${PROJECT}-bare.git"}

: ${AUTHORS_PATTERN:='$1 <$1>'}

: ${GIT_AUTHOR_FLAG:='--author="SVN 2 Git Migration <svn2git>"'}

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

function migrateIgnoredFiles {
    cd "$MIGRATE_DIR"
    git svn create-ignore
    git commit $GIT_AUTHOR_FLAG -m "Migrate svn:ignore to .gitignore" .gitignore

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

createAuthorsFile
checkoutGitSVN
migrateTags
migrateBranches
migrateIgnoredFiles
cloneBare
pushBareClone
