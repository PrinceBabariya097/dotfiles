#!/bin/bash

# Dedicated temporary cache folder purely for clipboard media to prevent lag
THUMB_DIR="/tmp/cliphist-thumbs"
mkdir -p "$THUMB_DIR"

tmp_list="/tmp/cliphist_list"
tmp_ui="/tmp/cliphist_ui"

cliphist list > "$tmp_list"

# Smart Cache Engine: 
# Pre-decode ONLY the top 15 most recent images to guarantee the UI opens instantly.
grep '\[\[ binary data' "$tmp_list" | head -n 15 | while IFS=$'\t' read -r id content; do
    if [[ ! -f "$THUMB_DIR/$id.png" ]]; then
        echo "$id" | cliphist decode > "$THUMB_DIR/$id.png" 2>/dev/null
    fi
done

awk -v thumb_dir="$THUMB_DIR" -F'\t' 'BEGIN {
    NULL_BYTE = sprintf("%c", 0);
    META_SEP = sprintf("%c", 31);
}
{
    id=$1;
    content=$2;
    icon_str=""
    if (content ~ /^\[\[ binary data/) {
        # Visual Title cleanup
        content = "   " content;
        gsub(/\[\[ binary data/, "Image: ", content);
        gsub(/\]\]/, "", content);
        
        # Safe construction of rofi property bindings using evaluated chars
        icon_str = NULL_BYTE "icon" META_SEP thumb_dir "/" id ".png"
    } else {
        # Format text snippets natively
        content = "󰅍   " content;
        gsub(/&/, "&amp;", content);
        gsub(/</, "&lt;", content);
        gsub(/>/, "&gt;", content);
        if (length(content) > 90) {
            content = substr(content, 1, 90) "...";
        }
    }
    
    # Rofi syntax magically accepts pure octal escapes to assign physical icons!
    printf "%s <span size=\"small\" alpha=\"40%%\">[#%s]</span>%s\n", content, id, icon_str;
}' "$tmp_list" > "$tmp_ui"

# Deploy formatted cache into Rofi
INDEX=$(cat "$tmp_ui" | rofi -dmenu -markup-rows -p "🔍" -theme ~/.config/rofi/clipboard.rasi -format i)

if [[ -n "$INDEX" && "$INDEX" -ge 0 ]]; then
    # Translate 0-index back to 1-index line for sed processing
    LINE=$((INDEX + 1))
    RAW_ITEM=$(sed -n "${LINE}p" "$tmp_list")
    
    # Actually copy the item
    echo "$RAW_ITEM" | cliphist decode | wl-copy
    
    # Extract just the content part for the notification
    CONTENT=$(echo "$RAW_ITEM" | cut -f2-)
    
    # Send appropriate notification context Based on Image vs Text
    if [[ "$CONTENT" =~ ^\[\[\ binary\ data ]]; then
        notify-send -t 2000 -a "Clipboard Manager" -i "image-x-generic" "Image Copied" "Snippet successfully copied to clipboard."
    else
        # Truncate string gracefully for the notification popup
        if [[ ${#CONTENT} -gt 60 ]]; then
            CONTENT="${CONTENT:0:60}..."
        fi
        # Escape any rogue symbols to guarantee clean notification
        CONTENT="${CONTENT//&/&amp;}"
        CONTENT="${CONTENT//</&lt;}"
        CONTENT="${CONTENT//>/&gt;}"
        
        notify-send -t 2000 -a "Clipboard Manager" -i "edit-copy" "Text Copied" "<i>${CONTENT}</i>"
    fi
fi
