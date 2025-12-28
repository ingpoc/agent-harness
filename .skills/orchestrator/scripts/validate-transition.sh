#!/bin/bash
# Validate state transition is allowed
# Usage: validate-transition.sh FROM TO
# Exit: 0 = valid, 1 = invalid

FROM=$1
TO=$2

# Valid transitions
case "$FROM" in
    "START")
        [[ "$TO" == "INIT" || "$TO" == "IMPLEMENT" ]] && exit 0
        ;;
    "INIT")
        [[ "$TO" == "IMPLEMENT" ]] && exit 0
        ;;
    "IMPLEMENT")
        [[ "$TO" == "TEST" ]] && exit 0
        ;;
    "TEST")
        [[ "$TO" == "IMPLEMENT" || "$TO" == "COMPLETE" ]] && exit 0
        ;;
    "COMPLETE")
        # Terminal state - no transitions allowed
        ;;
esac

echo "INVALID: $FROM -> $TO"
exit 1
