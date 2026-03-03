#Check size of the file in the archive
SIZE=$(7z l -slt ARCHIVE_NAME.7z | awk -F' = ' '
  $1=="Path" && $2=="ARCHIVE_CONTENTS.txt" {found=1}
  found && $1=="Size" {print $2; exit}
')

echo "Size of ARCHIVE_CONTENTS.txt: $SIZE bytes"

#Change the filenames in all caps to your desired value

7z x -so ARCHIVE_NAME.7z ARCHIVE_CONTENTS.txt \
| pv -s "$SIZE" \
| jq -r '.Email? // empty' \
| awk -F'@' 'NF==2 {print tolower($2)}' \
| grep -Fxi -f KEY.txt \
| sort -u -S 60% \
> OUTPUT.txt
