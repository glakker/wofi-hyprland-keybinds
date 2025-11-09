#!/bin/bash
# List hyprland keybinds in wofi
# Include remarks in hyprland config for keybind descriptions. E.g.:
# bind = $mainMod, Q, killactive #Close window


HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

# Extract all binds (bind, bindm, bindl, binde, etc.)
mapfile -t BINDINGS < <(
  grep '^bind' "$HYPR_CONF" | \
  sed -E 's/ *= */=/' | sed -e 's/, /,/g' | \
  awk -F'#' '{
    comment=$2; sub(/^[ \t]+/, "", comment);  # trim comment
    line=$1;
    n=split(line, parts, ",");
    gsub(/^bind[a-z]*=/, "", parts[1]);
    cmd="";
    for(i=3;i<=n;i++) cmd=cmd parts[i] " ";
    gsub(/^[ \t]+|[ \t]+$/, "", cmd);
    if(comment=="") comment="";
    # Escape &, <, > for markup safety
    gsub(/&/, "\\&amp;", cmd);
    gsub(/</, "\\&lt;", cmd);
    gsub(/>/, "\\&gt;", cmd);
    printf "%s + %s → %s <span color=\"gray\">%s</span>\n", parts[1], parts[2], comment, cmd;
  }'
)

# Show in Wofi (enable markup)
CHOICE=$(printf '%s\n' "${BINDINGS[@]}" | wofi -H 800 -W 650 --dmenu --allow-markup --prompt "Hyprland Keybinds:" 2>/dev/null)

# Extract the command (inside <span color="gray">...</span>)
CMD=$(echo "$CHOICE" | sed -n 's/.*<span color="gray">\([^<]*\)<\/span>.*/\1/p' | \
       sed -e 's/&amp;/\&/g' -e 's/&lt;/</g' -e 's/&gt;/>/g' | xargs)

# Execute selected command
if [[ -z "$CMD" ]]; then
  exit 0
elif [[ $CMD == exec* ]]; then
  eval "$CMD"
else
  hyprctl dispatch $CMD
fi

