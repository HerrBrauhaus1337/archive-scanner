clean_key=$(mktemp)
#  - Remove Windows CR (\r)
#  - Trim leading/trailing spaces/tabs
#  - Delete completely empty lines
sed 's/\r$//; s/^[[:space:]]*//; s/[[:space:]]*$//' Test.txt |
grep -v '^$' >"$clean_key"
