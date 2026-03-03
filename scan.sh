#Change the filenames in all caps to your desired value

7z x -so ARCHIVE_NAME.7z ARCHIVE_CONTENTS.txt \
| pv -s "$SIZE" \
| jq -r '.Email? // empty' \
| awk -F'@' 'NF==2 {print tolower($2)}' \
| grep -Fxi -f KEY.txt \
| sort -u -S 60% \
> OUTPUT.txt
