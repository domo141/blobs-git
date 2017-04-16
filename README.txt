
Binary Large OBJects in Git
===========================

Last modified: Sun 16 Apr 2017 23:14:07 +0300 too

The script 'blobs-git' provides a way to store and load single files
from a (separate) git repository. This is one attempt to "solve" the
storage side of 'large file support' with git repositories.
'blobs-git' works over ssh, http[s], git and local file protocols.

The idea (3rd iteration of it) is that each of the file is written
to a separate branch, which name is content-addressable name of
the file to be written. The content-addressable of a file is
created by concatenating sha-256 checksum of the file, '+' or '-'
(whether file more is 755 or 644, respectively) and size of the
file. The filename if this single file in each branch, is also
the same content-addressable name just created.

Before using 'blobs-git' empty git repository is to be created
somewhere (blobs-git make has option --init-repo, which may be
used in some cases, but not always). When this is done,
./blobs-git make {repository} can be used to "mark" the repo as
binary storage repository (that basically sends README to the
master branch of that repository).

After that './blobs-git send {repo} files...' can be used to upload
files to this new repo. Before each file, either 755 or 644 can
be given to set the remote permissions -- otherwise the current
(executable) permission determines what will the remote permission
be.

After uploaded, './blobs-git pick {repo} {target-dir} {ca-name...}'
can be used to download the files to target-dir. An example
download:

$ ./blobs-git pick origin-blobs %/../blobs \
    e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855-0

would, when located in a git repo, look its remote origin, and append
'-blobs' to its expanded location, and from there pick zero-sized blob,
with permissions 0644 and write the downloaded blob to ../blobs directory
related to the root directory of  current git working copy.

The last command introduced, './blobs-git list [--raw] {repo}' lists
all refs of the repository. In remote repositories this "whispers"
the query using curl or wget and locally runs find(1) over the "refs"
directory -- and git// repos are handled with simple custom perl code.
As the refs names are the content-addressable names of the files, from
this list one can figure out the state of these 'blobs' repositories.

For demonstration purposes, this repository contains also branches
for all of these files (unsurprisingly stored using this tool).
Internally it doesn't cause any increase in storage size, as the blobs
are the same as in this 'master' branch.
Simple integrity-checking test-demo.sh tool is in works, and may
appear here any week now...
