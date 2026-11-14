#!/system/bin/sh
# 由 adb 以 com.termux 身份启动，给 Termux 二进制补上环境变量
PREFIX=/data/data/com.termux/files/usr
HOME=/data/data/com.termux/files/home
export PREFIX HOME
export PATH="$PREFIX/bin:/system/bin:/system/xbin"
export LD_LIBRARY_PATH="$PREFIX/lib"
export TMPDIR="$PREFIX/tmp"
mkdir -p "$TMPDIR"
DIR="${1:-$HOME/arduino-mobile-toolchain}"
cd "$DIR" || exit 1
exec "$PREFIX/bin/bash" "$DIR/setup.sh" > "$DIR/setup.log" 2>&1
