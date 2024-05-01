#!/usr/bin/env bash

if [ "$DUNST_BODY" != "^Volume" ] && [ "$DUNST_BODY" != "^Brightness" ]; then
    pw-play ~/.local/share/sounds/tuturu.mp3
elif [ "$DUNST_BODY" = "^Battery low" ]; then
    pw-play ~/.local/share/sounds/hungaaa.mp3
elif [ "$DUNST_URGENCY" = "critical" ]; then
    pw-play ~/.local/share/sounds/kakegurui_subarashii.mp3
fi
