#!/bin/bash
# fuzzel app launcher; ctrl+tab (custom-1) switches to the window switcher.
# On custom-1 fuzzel still launches the selected app before exiting with 10,
# so its --launch-prefix (this script with --record) only saves the command,
# and the app is started here once fuzzel's exit code says it was a real pick.

if [[ $1 == --record ]]; then
    printf '%s\0' "${@:3}" > "$2"
    exit 0
fi

CMD=$(mktemp -u "${XDG_RUNTIME_DIR:-/tmp}/launcher.XXXXXX")
fuzzel --launch-prefix="$0 --record $CMD"
RC=$?
(( RC == 0 || RC == 10 )) || exit 0

# the prefix runs in a child fuzzel may outlive
for _ in {1..20}; do [[ -s $CMD ]] && break; sleep 0.05; done
if (( RC == 10 )); then
    rm -f "$CMD"
    exec /home/m/Dotfiles/scripts/window-switcher.sh
fi
[[ -s $CMD ]] || exit 0
mapfile -d '' -t ARGV < "$CMD"
rm -f "$CMD"
setsid -f "${ARGV[@]}" > /dev/null 2>&1
