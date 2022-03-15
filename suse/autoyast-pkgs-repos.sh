#!/bin/sh

#
# This script compares an autoyast profile against specific repo(s),
# then outputs a list of the autoyast profile packages that are not found.
# Repos must be registered on the system, but they do not have to be enabled.
#
# Inputs: 1) full path to autoyast profile
#         2) (optional with -r option) name(s) of repo(s).  By
#	     default, script will check all registered repos (enabled and
#	     disabled).
#
# Output: List of missing packages written to stdout.
#

# functions
function usage() {
	echo "Usage: `basename $0` [-h (usage)] [-d(ebug)] [-r repo] <autoyast-profile>"
}

# arguments
while getopts 'hdr:' OPTION; do
        case $OPTION in
                h)
                        usage
                        exit 0
                        ;;
                d)
                        DEBUG=1
                        ;;
		r)
			repo=`echo $OPTARG`
			repos="$repos $repo"
			;;
        esac
done
shift $((OPTIND - 1))
if [ ! "$1" ]; then
        usage >&2
	exit 1
else
	ayProfile="$1"
fi
if [ -z "$repos" ]; then
	repos=`zypper lr | grep -E "^[0-9]|^ [0-9]" | cut -d'|' -f2 | sed "s/ //g" | tr '\n' ' ' | sed "s/ $//g"`
fi
[ $DEBUG ] && echo "*** DEBUG: $0: ayProfile: $ayProfile" >&2
[ $DEBUG ] && echo "*** DEBUG: $0: repos: $repos" >&2

tmpDir=`mktemp -d`
[ $DEBUG ] && echo "*** DEBUG: $0: tmpDir: $tmpDir" >&2

echo ">>> Finding packages in $ayProfile..."
grep "<package>.*</package>" $ayProfile | sed "s/<package>//g" | sed "s/<\/package>//g" | sed "s/^ *//g" > $tmpDir/ayPkgList.tmp
plusContentOpts=""
repoOpts=""
for repo in $repos; do
	plusContentOpts="$plusContentOpts --plus-content $repo"
	repoOpts="$repoOpts -r $repo"
done
[ $DEBUG ] && echo "*** DEBUG: $0: plusContentOpts: $plusContentOpts" >&2
[ $DEBUG ] && echo "*** DEBUG: $0: repoOpts: $repoOpts" >&2
echo ">>> Checking against packages in repo(s)..."
zypper ${plusContentOpts} pa ${repoOpts}  | sed "1,4d" | cut -d '|' -f3 | sed "s/^ *//g" | sed "s/ *$//g" > $tmpDir/pkgsRepos.tmp

echo ">>> $ayProfile packages not found in repo(s):"
while IFS= read -r ayPkg; do
        [ $DEBUG ] && echo "*** DEBUG: $0: ayPkg: $ayPkg" >&2
	if grep -q "^$ayPkg$" $tmpDir/pkgsRepos.tmp; then
		[ $DEBUG ] && echo "*** DEBUG: $0: $ayPkg: Found" >&2
		continue
	else
		[ $DEBUG ] && echo "*** DEBUG: $0: $ayPkg: Not found" >&2
		echo $ayPkg
	fi
done < $tmpDir/ayPkgList.tmp

echo ">>> Cleaning up..."
rm -rf $tmpDir
