#!/data/data/com.termux/files/usr/bin/bash
# 第 1 阶段：Termux 原生层（包管理 + proot-distro）
#
# 用法：./setup.sh [项目名]     不传项目名则只装工具链
set -euo pipefail

PROFILE="${1:-${PROFILE:-}}"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
REL="${SELF_DIR#"$HOME"/}"
if [ "$REL" = "$SELF_DIR" ]; then
  echo "ERROR: 整个包必须放在 \$HOME 下（当前 $SELF_DIR）" >&2
  exit 1
fi

echo "== [1/3] 换清华源"
mkdir -p "$PREFIX/etc/apt"
echo "deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main" > "$PREFIX/etc/apt/sources.list"
pkg update -y

echo "== [2/3] 安装 proot-distro"
pkg install -y proot-distro

echo "== [3/3] 安装 Ubuntu"
if [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
  echo "已存在，跳过"
else
  proot-distro install ubuntu
fi

if [ -n "$PROFILE" ]; then
  echo "== 进入 Ubuntu 执行第 2 阶段（项目：$PROFILE）"
  proot-distro login ubuntu --bind "$HOME:/root/termux-home" -- \
    bash "/root/termux-home/$REL/ubuntu-setup.sh" "$PROFILE"
else
  echo "== 进入 Ubuntu 执行第 2 阶段（仅工具链）"
  proot-distro login ubuntu --bind "$HOME:/root/termux-home" -- \
    bash "/root/termux-home/$REL/ubuntu-setup.sh"
fi
echo "== 全部完成"
