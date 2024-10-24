#!/usr/bin/env nix-shell
#! nix-shell -i bash -p imagemagick

err() {
	echo
	echo ERROR: "$@" >&2
}
if [ "$1" == "CONVERT" ]; then
	f="$2"
	t=$(identify "$f" | sed 's/.*JPEG/JPEG/')
	set -- $t
	if [ "$1" != JPEG ]; then
		err "$f is not JPEG"
		exit 1
	fi
	set -- $(echo "$2"|sed 's/x/ /')
	if [ "$1" -gt 2000 ] || [ "$2" -gt 2000 ]; then
		if convert "$f" -quality 60 -resize "7680x7680>" out.jpg; then
			touch -r "$f" out.jpg
			# mv "$f"{,-ORIG.jpg} && \
			mv out.jpg "$f" && echo -n . || err "WTF? $f"
		else
			err "$f problem"
		fi
	else
		err "$f: too small, not recoding"
	fi

	exit 0
fi

if [ -z "$1" ]; then
	echo "Usage: $0 path_to_dir_with_big_jpgs..." >&2
	exit 1
fi
echo "About to recode jpeg files bigger than 1.5MB under $*"
echo "Are you sure? Ctrl-C if not."
read foo

find "$@" -type f -iregex '.*\.jpe?g$' \! -name '*-ORIG.jpg' -size +1500k -exec bash "$0" CONVERT {} \;
