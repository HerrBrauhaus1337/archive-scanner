#!/usr/bin/env bash
set -euo pipefail

ARCHIVE="Full-Leak.7z"
MEMBER="full_odido_shinyhunters.txt"
KEYFILE="Deelnemers.txt"
OUT="OUTPUT2.txt"

export LC_ALL=C
CORES="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"

# ------------------------------------------------------------
# 0) Clean KEYFILE -> lowercase domains
# ------------------------------------------------------------
clean_key=$(mktemp)
awk '
  {
    gsub(/\r$/, "", $0)
    sub(/^[[:space:]]+/, "", $0)
    sub(/[[:space:]]+$/, "", $0)
    if ($0 != "") print tolower($0)
  }
' "$KEYFILE" > "$clean_key"

# ------------------------------------------------------------
# 1) Determine size for accurate pv progress
# ------------------------------------------------------------
SIZE=$(
  7z l -slt "$ARCHIVE" |
  awk -F' = ' -v member="$MEMBER" '
    $1=="Path" && $2==member {found=1}
    found && $1=="Size" {print $2; exit}
  '
)

if [[ -n "${SIZE:-}" ]]; then
  echo "📦 Streaming $MEMBER ($SIZE bytes)" >&2
  PV_CMD=(pv -s "$SIZE")
else
  echo "⚠️ Size unknown — pv without ETA" >&2
  PV_CMD=(pv)
fi

# ------------------------------------------------------------
# 2) Stream JSON (as text) → remove literal JSON escapes like \t → extract emails
# ------------------------------------------------------------
7z x -so "$ARCHIVE" "$MEMBER" \
| "${PV_CMD[@]}" \
| sed -E 's/\\t//g; s/\\n//g; s/\\r//g; s/\\u0009//g' \
| grep -Eoi '[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}' \
| awk -F'@' '
    NR==FNR { domains[$0]=1; next }
    NF==2 {
      dom = tolower($2)
      if (dom in domains) print tolower($0)
    }
' "$clean_key" - \
| sort -u --parallel="$CORES" -S 80% \
> "$OUT"

echo "🗒️ Finished – $(wc -l <"$OUT") unique e-mails saved to $OUT" >&2
rm -f "$clean_key"
