#!/bin/sh

validate_md5() {
	filename=$1
	md5_hash=$2

	md5_match=`md5sum $filename | cut -d' ' -f1`

	if [ "$md5_match" == "$md5_hash" ]; then
		matches=0
	else
		matches=1
	fi

	return $matches
}

echo $SKIP

if [ ${SKIP:-n} == n ]; then
	for list in $@; do
		while read line; do
			components=($line)

			url=${components[0]}
			md5_hash=${components[1]}

			filename=`basename $url`

			if [ -f $filename ] && ! validate_md5 $filename $md5_hash; then
				echo Invalid MD5 hash for file $filename.
				rm $filename
			fi

			if [ ! -f $filename ]; then
				echo Downloading $url
				curl -L -# -O $url
			else
				echo Skipping $url
			fi

		done < $list
	done
fi
