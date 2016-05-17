# SVN-2-Git
SVN-2-Git (svn2git) is a script to ease migration from Subversion to Git.

## Prerequisites
To be able to use svn2git, the following prerequisites are assumed:
* /bin/bash
* svn (Subversion)
* git (with git-svn)

## Usage
Usage: svn2git.bash `<parameters>`

| Short | Long | Description | Required / Optional |
|---|---|---|---|
| `-p <projectname>` | `--project=<projectname>` | Sets the name of the project to migrate. | Required unless `PROJECT` env variable is set. |
| `-s <svn repository>` | `--svn=<svn repository>` | Sets the Subversion Repository URL. *Important is that this points to the* ***root*** *of the Subversion repository, so trunk, tags and branches are accessible* | Required unless `SVN_REPOSITORY` env variable is set. |
| `-g <git repository>` | `--git=<git repository>` | Sets the Git Repository URL. This repository should *exist and be empty*. | Required unless `GIT_REPOSITORY` env variable is set. |
| | `--no-metadata` | Don't keep the reference to the original SVN revision in the migrated Git repository | Optional |
| `-T <dir>` | `--trunk=<dir>` | The trunk of the SVN repository (relative to the root). *Should only be used for a non-standard Subversion layout* | Optional |
| `-b <dir>` | `--branches=<dir>` | A branches subdirectory of the SVN repository (relative to the root). Can occur multiple times. *Should only be used for a non-standard Subversion layout* | Optional |
| `-t <dir>` | `--tags=<dir>` | A tags subdirectory of the SVN repository (relative to the root). Can occur multiple times. *Should only be used for a non-standard Subversion layout* | Optional |
| `-v` | `--verbose` | Run in verbose mode | Optional |
| `-h` | `--help` | Print this message and exit | Optional |

### Examples
Migrating **myproject** from `svn://myproject.code.svn` to `ssh://git@myproject.code.git`. The project has a standard Subversion structure, and Subversion revision information is kept during migration.
```
$ svn2git.bash -p myproject -s svn://myproject.code.svn -g ssh://git@myproject.code.git
```

Migrating **myproject** from `svn://myproject.code.svn` to `ssh://git@myproject.code.git`. The project has a standard Subversion structure, and Subversion revision information is discarded during migration.
```
$ svn2git.bash -p myproject -s svn://myproject.code.svn -g ssh://git@myproject.code.git --no-metadata
```

Migrating **myproject** from `svn://myproject.code.svn` to `ssh://git@myproject.code.git`. The project's trunk is in `code`, branches are in `old_branches` and `new_brances` and tags are in `tags`. Subversion revision information is kept during migration.
```
$ svn2git.bash -p myproject -s svn://myproject.code.svn -g ssh://git@myproject.code.git -T code -b old_branches -b new_branches -t tags
```

## Legal
### Copyright
Copyright 2016 Stefan Rotman - Puzzle ITC GmbH <rotman@puzzle.ch>

### Licensing
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

