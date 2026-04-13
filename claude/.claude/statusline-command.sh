#!/bin/sh
input=$(cat)

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# Build a 10-char progress bar with color (green → yellow → red)
# Usage: make_bar <percentage>
make_bar() {
  pct=$1
  filled=$(( pct * 10 / 100 ))
  empty=$(( 10 - filled ))

  if [ "$pct" -lt 50 ]; then
    color="\033[32m"   # green
  elif [ "$pct" -lt 80 ]; then
    color="\033[33m"   # yellow
  else
    color="\033[31m"   # red
  fi

  bar=""
  i=0
  while [ $i -lt $filled ]; do bar="${bar}●"; i=$(( i + 1 )); done
  i=0
  while [ $i -lt $empty ];  do bar="${bar}○"; i=$(( i + 1 )); done

  printf "%b%s\033[0m" "$color" "$bar"
}

if [ -n "$used_pct" ]; then
  ctx_pct=$(printf '%.0f' "$used_pct")
  printf "\033[2mCtx \033[0m"
  make_bar "$ctx_pct"
  printf "\033[2m %s%%\033[0m" "$ctx_pct"
else
  printf "\033[2mCtx ○○○○○○○○○○ 0%%\033[0m"
fi

if [ -n "$five_hour" ]; then
  rate_pct=$(printf '%.0f' "$five_hour")

  reset_str=""
  if [ -n "$resets_at" ]; then
    now=$(date +%s)
    diff=$(( resets_at - now ))
    if [ "$diff" -gt 0 ]; then
      h=$(( diff / 3600 ))
      m=$(( (diff % 3600) / 60 ))
      if [ "$h" -gt 0 ]; then
        reset_str=" · ${h}h ${m}m"
      else
        reset_str=" · ${m}m"
      fi
    fi
  fi

  printf "\033[2m  |  5h \033[0m"
  make_bar "$rate_pct"
  printf "\033[2m %s%%%s\033[0m" "$rate_pct" "$reset_str"
fi

printf "\n"
