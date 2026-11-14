#!/usr/bin/env bash
# 第 2 阶段：proot Ubuntu 内 —— 装工具链，可选还原一个项目
#
# 用法（Termux 里，setup.sh 会自动调用）：
#   proot-distro login ubuntu --bind "$HOME:/root/termux-home" -- \
#     bash /root/termux-home/<包目录>/ubuntu-setup.sh [项目名]
#
# 项目名对应 projects/<项目名>/；不传则只装工具链。
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE="${1:-${PROFILE:-}}"

echo "== [1/3] Ubuntu 换清华源"
if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
  sed -i -E 's#https?://(archive|security)\.ubuntu\.com/ubuntu/?#https://mirrors.tuna.tsinghua.edu.cn/ubuntu/#g' /etc/apt/sources.list.d/ubuntu.sources
fi
sed -i -E 's#https?://(archive|security)\.ubuntu\.com/ubuntu/?#https://mirrors.tuna.tsinghua.edu.cn/ubuntu/#g' /etc/apt/sources.list 2>/dev/null || true

if [ -n "$PROFILE" ]; then
  PROJECT_DIR="$SELF_DIR/projects/$PROFILE"
  if [ ! -f "$PROJECT_DIR/project.sh" ]; then
    echo "ERROR: 没有 projects/$PROFILE/project.sh" >&2
    echo "       现有项目：$(ls "$SELF_DIR/projects" 2>/dev/null | tr '\n' ' ')" >&2
    exit 1
  fi
  # shellcheck source=/dev/null
  . "$PROJECT_DIR/project.sh"

  echo "== [2/3] 还原项目 $PROJECT_NAME"
  SRC_DIR="$PROJECT_DIR/src/$PROJECT_NAME"
  mkdir -p "$(dirname "$SRC_DIR")"
  if [ -d "$SRC_DIR" ]; then
    echo "   已存在，跳过 clone"
  elif [ -f "$PROJECT_DIR/$PROJECT_BUNDLE" ]; then
    case "$PROJECT_BUNDLE" in
      *.tar.gz|*.tgz)
        mkdir -p "$SRC_DIR"
        tar xzf "$PROJECT_DIR/$PROJECT_BUNDLE" -C "$SRC_DIR" --strip-components=1
        ;;
      *)
        git clone "$PROJECT_DIR/$PROJECT_BUNDLE" "$SRC_DIR"
        ;;
    esac
  elif [ -d "$PROJECT_DIR/$PROJECT_BUNDLE" ]; then
    cp -a "$PROJECT_DIR/$PROJECT_BUNDLE" "$SRC_DIR"
  else
    echo "ERROR: 找不到 $PROJECT_DIR/$PROJECT_BUNDLE" >&2
    exit 1
  fi

  if [ -n "${PROJECT_OVERLAY:-}" ] && [ -f "$PROJECT_DIR/$PROJECT_OVERLAY" ]; then
    tar xzf "$PROJECT_DIR/$PROJECT_OVERLAY" -C "$SRC_DIR"
  fi

  # 补 .gitignore 挡掉的文件，每行 "源:目标目录"
  while IFS=: read -r src dst; do
    src="${src%$'\r'}"; dst="${dst%$'\r'}"
    [ -z "$src" ] && continue
    mkdir -p "$SRC_DIR/$dst"
    cp "$PROJECT_DIR/$src" "$SRC_DIR/$dst/"
    echo "   + $src → $dst"
  done <<< "${PROJECT_EXTRA_FILES:-}"
else
  echo "== [2/3] 未指定项目，跳过源码还原"
fi

echo "== [3/3] 工具链"
CORES="${PROJECT_CORE:-esp32:esp32@3.3.6}" LIBS="${PROJECT_LIBS:-}" "$SELF_DIR/toolchain-setup.sh"

echo
if [ -n "$PROFILE" ]; then
  echo "== 完成：cd $SRC_DIR"
  echo "   编译/烧录脚本由项目自己提供"
else
  echo "== 完成：工具链已就绪（arduino-cli / esp32 core / Claude Code）"
  echo "   接项目：在 projects/<名字>/ 放 project.sh，见 projects/README.md"
fi
