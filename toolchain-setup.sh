#!/usr/bin/env bash
# toolchain-setup.sh — 在 proot Ubuntu 里装 arduino-cli + core + 库 + Claude Code
#
# 用法：
#   CORES="esp32:esp32@3.3.6 arduino:avr" LIBS="MyLib" ./toolchain-setup.sh
# 环境变量：
#   CORES          空格分隔的 arduino-cli core，默认 esp32:esp32@3.3.6
#   LIBS           空格分隔的库名
#   INSTALL_CLAUDE 1/0，默认 1
set -euo pipefail
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
CORES="${CORES:-esp32:esp32@3.3.6}"
LIBS="${LIBS:-}"
INSTALL_CLAUDE="${INSTALL_CLAUDE:-1}"

case "$(uname -m)" in
  aarch64|arm64) ;;
  *) echo "WARN: $(uname -m)，随包工具链是 aarch64（手机请用 arm64）" >&2 ;;
esac

echo "== 1/4 基础依赖"
apt-get update
apt-get install -y --no-install-recommends \
  curl ca-certificates git python3 xz-utils unzip telnet

echo "== 2/4 arduino-cli"
if ! command -v arduino-cli >/dev/null 2>&1; then
  LOCAL_TAR="${ARDUINO_CLI_TAR:-$SELF_DIR/arduino-cli.tar.gz}"
  if [ -f "$LOCAL_TAR" ]; then
    tar xzf "$LOCAL_TAR" -C /usr/local/bin arduino-cli
  else
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
    install -m 755 bin/arduino-cli /usr/local/bin/arduino-cli
  fi
fi
arduino-cli version

echo "== 3/4 core / 库"
arduino-cli config init --overwrite >/dev/null
for spec in $CORES; do
  id="${spec%@*}" ver=""
  case "$spec" in *@*) ver="${spec##*@}" ;; esac
  if arduino-cli core list 2>/dev/null | grep -qE "^${id}[[:space:]]+${ver:-[^[:space:]]+}"; then
    echo "   $spec 已装，跳过"
    continue
  fi
  # 只有真要装才联网拉索引（已装好的环境可离线重跑）
  arduino-cli core update-index
  arduino-cli core install "$spec"
done

mkdir -p "$HOME/Arduino/libraries"
for lib in $LIBS; do
  if [ -d "$HOME/Arduino/libraries/$lib" ]; then
    echo "   $lib 已装，跳过"
  elif [ -f "$SELF_DIR/arduino-offline/$lib.tar.gz" ]; then
    # 本地包顶层就是库目录名，直接解到 libraries/
    tar xzf "$SELF_DIR/arduino-offline/$lib.tar.gz" -C "$HOME/Arduino/libraries"
  else
    arduino-cli lib install "$lib"
  fi
done

echo "== 4/4 Claude Code"
if [ "$INSTALL_CLAUDE" = "1" ]; then
  if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
  fi
  claude --version
fi

echo "== 自检"
for spec in $CORES; do
  id="${spec%@*}" ver=""
  case "$spec" in *@*) ver="${spec##*@}" ;; esac
  arduino-cli core list | grep -qE "^${id}[[:space:]]+${ver:-[^[:space:]]+}" \
    || { echo "FAIL core 未装好: $spec" >&2; exit 1; }
done
for lib in $LIBS; do
  [ -d "$HOME/Arduino/libraries/$lib" ] || { echo "FAIL 库未装好: $lib" >&2; exit 1; }
done
echo "OK 工具链就绪"
