#!/bin/sh

for f in /usr/bin/scripts/pre_*.sh; do
	    # if this execution fails, then stop the `for`:
	echo "Executing $f"
	if ! bash "$f"; then
		echo "There was an error when executing script $f. Ignoring rest of the scripts"
		break;
	fi
done
