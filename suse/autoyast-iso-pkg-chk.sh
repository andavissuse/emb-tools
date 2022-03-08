#!/bin/sh

#
# This script compares an autoyast profile against an iso/directory/mnt-point
# then outputs a list of packages that are not provided by the iso.
#
# Inputs: 1) full path to autoyast profile
#         2) full path to iso or directory/mount-point
#
# Output: Package additions written to ./pkgs-missing.txt.
#

# functions
function usage() {
	echo "Usage: `basename $0` [-h (usage)] [-d(ebug)] <autoyast-profile> <iso-or-dir/mntpt>"
}

# arguments
while getopts 'hd' OPTION; do
        case $OPTION in
                h)
                        usage
                        exit 0
                        ;;
                d)
                        DEBUG=1
                        ;;
        esac
done
shift $((OPTIND - 1))
if [ ! "$2" ]; then
        usage >&2
	exit 1
fi

tmpDir=`mktemp -d`
[ $DEBUG ] && echo "*** DEBUG: $0: tmpDir: $tmpDir" >&2
if [ ! -r "$1" ]; then
	echo "No autoyast profile provided, exiting..." >&2
	usage >&2
	exit 1
else
	ayProfile="$1"
fi
if [ -f "$2" ]; then
	mkdir $tmpDir/mnt
	echo ">>> Mounting $2 on $tmpDir/mnt..."
	if ! mount -o loop "$2" $tmpDir/mnt >/dev/null 2>&1; then 
		echo "Error mounting $2, exiting..." >&2
		usage >&2
		exit 1
	else
		pathToChk="$tmpDir/mnt"
	fi
elif [ -d "$2" ]; then
	pathToChk="$2"
else
	usage >&2
	exit 1
fi
[ $DEBUG ] && echo "*** DEBUG: $0: ayProfile: $ayProfile" >&2
[ $DEBUG ] && echo "*** DEBUG: $0: pathToChk: $pathToChk" >&2

grep "<package>.*</package>" $ayProfile | sed "s/<package>//g" | sed "s/<\/package>//g" | sed "s/^ *//g" > $tmpDir/ayPkgList.tmp

echo ">>> Checking packages (this may take several minutes)..."
while IFS= read -r ayPkg; do
	[ $DEBUG ] && echo "*** DEBUG: $0: ayPkg: $ayPkg" >&2
	isoPkgs=`find $pathToChk -name $ayPkg*.rpm`
	[ $DEBUG ] && echo "*** DEBUG: $0: isoPkgs: $isoPkgs" >&2
	found="n"
	if [ ! -z "$isoPkgs" ]; then
		for isoPkg in $isoPkgs; do
			[ $DEBUG ] && echo "*** DEBUG: $0: isoPkg: $isoPkg" >&2
			isoPkgName=`rpm -qp --queryformat "%{NAME}" $isoPkg`
			isoPkgVer=`rpm -qp --queryformat "%{VERSION}" $isoPkg`
			[ $DEBUG ] && echo "*** DEBUG: $0: isoPkgName: $isoPkgName, isoPkgVer: $isoPkgVer" >&2
			if [ "$isoPkgName" = "$ayPkg" ] || [ "$isoPkgName-$isoPkgVer" = "$ayPkg" ]; then
				[ $DEBUG ] && echo "*** DEBUG: $0: Found $ayPkg" >&2
				found="y"
				break
			fi
		done
	fi
	if [ "$found" = "n" ]; then
		[ $DEBUG ] && echo "*** DEBUG: $0: Did not find $ayPkg" >&2
		echo $ayPkg >> ./pkgs-missing.txt
	fi
done < $tmpDir/ayPkgList.tmp

echo ">>> Cleaning up..."
umount $tmpDir/mnt >/dev/null 2>&1
rm -rf $tmpDir
