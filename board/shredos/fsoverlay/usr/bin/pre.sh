#!/bin/sh

for f in pre_*.sh; do
	    # if this execution fails, then stop the `for`:
	echo "Executing $f"
	if ! bash "$f"; then
		break;
		echo "There was an error when executing script $f. Ignoring rest of the scripts"
	fi
done
