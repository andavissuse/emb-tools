#!/bin/sh

#
# This script outputs sorted lists of package (rpm) additions and deletions
# between 2 isos or directories/mount-points.
#
# Inputs: 1) full path to iso1 or directory/mount-point-1
#         2) full path to iso2 or directory/mount-point-2
#
# Output: Package additions and deletions written to stdout.
#

# functions
function usage() {
	echo "Usage: `basename $0` [-h (usage)] [-d(ebug)] <iso1-or-dir/mntpt1> <iso2-or-dir/mntpt2>"
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
if [ -f "$1" ]; then
	mkdir $tmpDir/mnt1
	echo ">>> Mounting $1 on $tmpDir/mnt1..."
	if ! mount -o loop "$1" $tmpDir/mnt1 >/dev/null 2>&1; then 
		echo "Error mounting $1." >&2
		usage >&2
		exit 1
	else
		path1="$tmpDir/mnt1"
	fi
elif [ -d "$1" ]; then
	path1="$1"
else
	usage >&2
	exit 1
fi
if [ -f "$2" ]; then 
	mkdir $tmpDir/mnt2
	echo ">>> Mounting $2 on $tmpDir/mnt2..."
	if ! mount -o loop "$2" $tmpDir/mnt2 >/dev/null 2>&1; then
		echo "Error mounting $2." >&2
		usage >&2
		exit 1
	else
		path2="$tmpDir/mnt2"
	fi
elif [ -d "$2" ]; then
	path2="$2"
else
	usage >&2
	exit 1
fi
[ $DEBUG ] && echo "*** DEBUG: $0: path1: $path1" >&2
[ $DEBUG ] && echo "*** DEBUG: $0: path2: $path2" >&2

echo ">>> Building package lists and comparing (this may take several minutes)..."
for pkg in `find $path1 -name *.rpm`; do
	rpmname=`rpm -qp --queryformat %{NAME} $pkg 2>/dev/null`
	echo "$rpmname" >> $tmpDir/path1rpms.txt
done
for pkg in `find $path2 -name *.rpm`; do
	rpmname=`rpm -qp --queryformat %{NAME} $pkg 2>/dev/null`
	echo "$rpmname" >> $tmpDir/path2rpms.txt
done

cat $tmpDir/path1rpms.txt | sort -u > $tmpDir/path1rpms-sorted.txt
cat $tmpDir/path2rpms.txt | sort -u > $tmpDir/path2rpms-sorted.txt

echo ">>> Packages added in $2:"
comm -13 $tmpDir/path1rpms-sorted.txt $tmpDir/path2rpms-sorted.txt

echo ">>> Packages deleted in $2:"
comm -23 $tmpDir/path1rpms-sorted.txt $tmpDir/path2rpms-sorted.txt

echo ">>> Cleaning up..."
umount $tmpDir/mnt? >/dev/null 2>&1
rm -rf $tmpDir
