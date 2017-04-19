#!/bin/sh
# -*- mode: shell-script; sh-indentation: 8; tab-width: 8 -*-
# $ test-demo.sh $
#
# Author: Tomi Ollila -- too ät iki piste fi
#
#	Copyright (c) 2017 Tomi Ollila
#	    All rights reserved
#
# Created: Mon 17 Apr 2017 10:30:07 EEST too
# Last modified: Wed 19 Apr 2017 18:32:23 +0300 too

case ~ in '~') echo "'~' does not expand. old /bin/sh?" >&2; exit 1; esac

case ${BASH_VERSION-} in *.*) set -o posix; shopt -s xpg_echo; esac
case ${ZSH_VERSION-} in *.*) emulate ksh; esac

set -u  # expanding unset variable makes non-interactive shell exit immediately
set -f  # disable pathname expansion by default
set -e  # exit on error -- know potential false negatives and positives !
#et -x  # s/#/s/ may help debugging  (or run /bin/sh -x ... on command line)

# LANG=C.UTF-8 LC_ALL=C.UTF-8; export LANG LC_ALL; unset LANGUAGE
# LANG=en_IE.UTF-8 LC_ALL=en_IE.UTF-8; export LANG LC_ALL; unset LANGUAGE
# PATH='/sbin:/usr/sbin:/bin:/usr/bin'; export PATH

saved_IFS=$IFS; readonly saved_IFS

wc=0
warn () { printf '%s\n' "$*"; wc=$((wc + 1)); } >&2
die () { printf '%s\n' "$*"; exit 1; } >&2

x () { printf '+ %s\n' "$*" >&2; "$@"; }
x_env () { printf '+ %s\n' "$*" >&2; env "$@"; }
x_eval () { printf '+ %s\n' "$*" >&2; eval "$*"; }
x_exec () { printf '+ %s\n' "$*" >&2; exec "$@"; die "exec '$*' failed"; }

umask 022

echo
echo The idea is to have the \"blobs\" repositories separated from normal git
echo repositories. For demonstration purposes this repo is supposed to hold
echo all the files reachable from master HEAD commit also as individually
echo pickable files in this same repository '(with addtion of "/dev/null")'
echo This script tests and demonstrates this presumption:
echo

test "${1-}" = '!' || {
	echo "This demo will pick all the files in blobs branches in this"
	echo "repository and compare their content with their name and with"
	echo "local content. To execute this, append '!' to the command line."
	echo; exit 0
}
tmpdir=`mktemp -d td.XXXXXX`
trap 'rm -rf $tmpdir; trap - 0' 0 INT HUP TERM QUIT

# remote is (most probably) sorted already, but don't depend on it.
./blobs-git list origin | sed -n '/.............../ s/ *//p' | sort > $tmpdir/remote-branches
echo
echo Remote branches:
cat $tmpdir/remote-branches

for file in `exec git ls-files` /dev/null
do
	size=`exec stat -c %s "$file"`
	test -x "$file" && sep=+ || sep=-
	case ${#size} in 4) s='  ';; 1) s='     ';; *) s=' ';; esac
	openssl sha256 -r "$file" | sed "y/*/ /; s/  */$sep$size$s/"
	#openssl sha256 "$file" | sed "s/.* //; s:$:$sep$size$s$file:"
done | sort > $tmpdir/local-sums
echo
echo Local sums:
cat $tmpdir/local-sums

echo
echo Comparing...
x_eval 'sed "s/ .*//" $tmpdir/local-sums | diff -u - $tmpdir/remote-branches' ||
	warn "Differences found..."

echo
echo Pick the files listed in "'remote branches'":

rbf=`exec cat $tmpdir/remote-branches`

x ./blobs-git pick origin $tmpdir $rbf

echo
echo Compare picked filenamess with their content:
for file in $rbf
do
	size=`exec stat -c %s "$tmpdir/$file"`
	test -x "$tmpdir/$file" && sep=+ || sep=-
	tf=`exec openssl sha256 "$tmpdir/$file"` tf=${tf#* }$sep$size
	if test $tf != $file
	then
		warn "Calculated filename '$tf'"
		warn "does not match '$file'"
		wc=$((wc - 1))
	else
		case ${#size} in 4) s='  ';; 1) s='     ';; *) s=' ';; esac
		echo "$file:${s}matches content"
	fi
done

echo
if test $wc = 0
then
	echo 'The "embedded" demonstration blobs branches are in sync \o/'
else
	test $wc = 1 && differences=difference || differences=differences
	echo "$wc $differences found. Update!"
fi
