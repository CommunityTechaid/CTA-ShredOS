#!/bin/sh

if [ "$(ls -A /usr/bin/scripts/post_*.sh 2>/dev/null)" ]; then
	for f in /usr/bin/scripts/post_*.sh; do
		# if this execution fails, then stop the `for`:
		echo "Executing $f"
		if ! bash "$f"; then
			echo "There was an error when executing script $f. Ignoring rest of the scripts"
			break;
		fi
	done
else:
	echo "No post hook scripts to run"
fi
