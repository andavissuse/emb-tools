#!/bin/sh

#
# This script compares 2 SLE isos (or mountpoints of isos) to find packages that
# moved to different SLE modules.
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
for pkg in `find ${path1}/Module-* -name *.rpm`; do
        rpmname=`rpm -qp --queryformat %{NAME} $pkg 2>/dev/null`
	modOrProd=`echo $pkg | sed 's,'"$path1"',,' | cut -d'/' -f2`
        echo "$rpmname $modOrProd" >> $tmpDir/path1rpms.txt
done
for pkg in `find ${path2}/Module-* -name *.rpm`; do
        rpmname=`rpm -qp --queryformat %{NAME} $pkg 2>/dev/null`
	modOrProd=`echo $pkg | sed 's,'"$path2"',,' | cut -d'/' -f2`
        echo "$rpmname $modOrProd" >> $tmpDir/path2rpms.txt
done

cat $tmpDir/path1rpms.txt | sort -u > $tmpDir/path1rpms-sorted.txt
cat $tmpDir/path2rpms.txt | sort -u > $tmpDir/path2rpms-sorted.txt

while IFS= read -r line; do
	[ $DEBUG ] && echo "*** DEBUG: $0: line: $line" >&2
	rpmname=`echo $line | cut -d' ' -f1`
	[ $DEBUG ] && echo "*** DEBUG: $0: rpmname: $rpmname" >&2
	mod1name=`echo $line | cut -d' ' -f2`
	[ $DEBUG ] && echo "*** DEBUG: $0: mod1name: $mod1name" >&2
	mod2name=`grep -E "^${rpmname} " $tmpDir/path2rpms-sorted.txt | grep -F "${rpmname}" | cut -d' ' -f2`
	[ $DEBUG ] && echo "*** DEBUG: $0: mod2name: $mod2name" >&2
	if [ "$mod1name" = "$mod2name" ] || [ -z "$mod2name" ]; then
		continue
	else
		echo "$rpmname changed from $mod1name to $mod2name"
	fi
done < $tmpDir/path1rpms-sorted.txt

echo ">>> Cleaning up..."
umount $tmpDir/mnt? >/dev/null 2>&1
#rm -rf $tmpDir
