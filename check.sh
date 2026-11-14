#!/usr/bin/env bash
# check.sh — 结构自检，在 PC 或手机上都能跑，不需要 arduino-cli
set -euo pipefail
cd "$(dirname "$0")"

ok=0
fail=0
say_ok()   { echo "OK   $*"; ok=$((ok+1)); }
say_fail() { echo "FAIL $*"; fail=$((fail+1)); }

for f in setup.sh ubuntu-setup.sh toolchain-setup.sh check.sh projects/*/project.sh; do
  if bash -n "$f" 2>/dev/null; then say_ok "语法 $f"; else say_fail "语法 $f"; fi
done

for p in projects/*/project.sh; do
  [ -f "$p" ] || continue
  pdir="$(dirname "$p")"
  profile="$(basename "$pdir")"
  # shellcheck source=/dev/null
  ( . "$p"
    [ -n "${PROJECT_NAME:-}" ]            || { echo "FAIL $profile 缺 PROJECT_NAME"; exit 1; }
    [ -f "$pdir/$PROJECT_BUNDLE" ]        || { echo "FAIL $profile 缺 $PROJECT_BUNDLE"; exit 1; }
    if [ -n "${PROJECT_OVERLAY:-}" ]; then
      [ -f "$pdir/$PROJECT_OVERLAY" ]     || { echo "FAIL $profile 缺 $PROJECT_OVERLAY"; exit 1; }
    fi
    while IFS=: read -r src dst; do
      src="${src%$'\r'}"; dst="${dst%$'\r'}"
      [ -z "$src" ] && continue
      [ -f "$pdir/$src" ] || { echo "FAIL $profile 缺 $src"; exit 1; }
      [ -n "$dst" ]       || { echo "FAIL $profile $src 没写目标目录"; exit 1; }
    done <<< "${PROJECT_EXTRA_FILES:-}"
  ) && say_ok "项目 $profile" || say_fail "项目 $profile"
done

[ -f arduino-cli.tar.gz ] && say_ok "arduino-cli.tar.gz" || say_fail "arduino-cli.tar.gz"
[ -d arduino-offline ]    && say_ok "arduino-offline/"   || say_fail "arduino-offline/"

echo
echo "共 $ok 项通过，$fail 项失败"
[ "$fail" -eq 0 ]
