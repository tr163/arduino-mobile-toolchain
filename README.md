# Arduino Mobile Toolchain

在 Android 手机上跑完整的 Arduino / ESP32 开发工作流：Termux → proot Ubuntu →
arduino-cli（离线包）+ Claude Code。**不限于某个项目** —— 任何能放进
`projects/<名字>/` 的 Arduino/ESP32 工程都能用同一套环境编译、烧录、改代码。

---

## 目录结构

```
.
├── setup.sh                 # 第 1 阶段：Termux 原生层
├── ubuntu-setup.sh          # 第 2 阶段：proot Ubuntu 里装工具链 + 可选还原项目
├── toolchain-setup.sh       # 通用工具链：arduino-cli / core / 库 / Claude Code
├── check.sh                 # 不开机也能跑的结构自检
├── boot.sh                  # 由 adb 免交互启动 setup.sh
├── arduino-cli.tar.gz       # 离线 arduino-cli（aarch64，16 MB）
├── arduino-offline/         # 离线库 / core 素材（见该目录 README）
└── projects/
    └── README.md            # 怎么接一个 Arduino/ESP32 项目
```

> ESP32 core / Xtensa 工具链 / Ubuntu rootfs 等大文件（合计约 600 MB）超出
> GitHub 单文件 100 MB 限制，放在 [Releases](https://github.com/tr163/arduino-mobile-toolchain/releases)
> 页面，按需下载。它们只有做“完整离线 core 安装”时才用得到，日常安装走
> arduino-cli 在线拉取。

---

## 手机准备（一次性）

- Termux 从 **F-Droid** 或 GitHub Release 装，不要 Play 版
- 设置 → 应用 → Termux → 电池 → **无限制**，最近任务里上锁
- 开发者选项 → 后台进程限制 → 标准限制
  （Android 14+ 如「暂停执行已缓存的应用」也关掉）
- 整个包必须放在 `$HOME` 下（如 `~/arduino-mobile-toolchain`）

## 1. 把文件传到手机

**推荐：直接 clone**（Termux 里执行，需要联网一次）：

```bash
pkg install -y git
git clone https://github.com/tr163/arduino-mobile-toolchain.git ~/arduino-mobile-toolchain
```

**离线：MTP / 同 WiFi 传目录**

- **MTP**：USB 连接 → 把整个仓库目录拷到 `Download/`
- **同 WiFi**：PC 在本目录 `python -m http.server 8000`，手机 `curl -O http://<PC-IP>:8000/...`

```bash
mkdir -p ~/arduino-mobile-toolchain
cp -r ~/storage/downloads/arduino-mobile-toolchain/* ~/arduino-mobile-toolchain/
```

## 2. 一键安装

```bash
cd ~/arduino-mobile-toolchain
./setup.sh                 # 只装工具链（arduino-cli + esp32 core + Claude Code）
./setup.sh <项目名>        # 还原 projects/<项目名>/，并按它声明的 core/库安装
```

`setup.sh` 会：装 proot-distro + Ubuntu → 换清华源 →（可选）还原项目 →
装 arduino-cli、项目声明的 core、库和 Claude Code。

## 3. 日常使用

```bash
cd ~/arduino-mobile-toolchain/projects/<项目名>/src/<PROJECT_NAME>
claude                     # 改代码
# 编译 / 烧录命令由项目自己提供（build.sh、ota.sh、make ...）
```

---

## 接一个新项目

每个项目一个目录：`projects/<名字>/`，至少两个文件：

```
projects/<名字>/
├── project.sh      # 项目配置
└── <源码包>        # git bundle / tar.gz / 目录
```

复制一份 `project.sh` 模板并改这几行：

```bash
PROJECT_NAME="MyBoard"             # 还原后的目录名
PROJECT_BUNDLE="src.tar.gz"        # git bundle / tar.gz / 目录
PROJECT_OVERLAY=""                 # 可选，解压到源码根（未提交改动）
PROJECT_CORE="esp32:esp32@3.3.6"   # AVR: arduino:avr；其他 ESP32 版本同理
PROJECT_LIBS="MyLib OtherLib"
PROJECT_EXTRA_FILES="secret.h:src/"
```

把源码包放进同目录，然后 `./setup.sh <名字>`。源码会还原到
`projects/<名字>/src/<PROJECT_NAME>/`。项目的编译/烧录脚本不归工具链管 ——
FQBN、分区表、烧录方式因项目而异。详见 [projects/README.md](projects/README.md)。

## 离线说明

- `arduino-cli.tar.gz` 自动使用，不需要联网
- `arduino-offline/<库名>.tar.gz` 自动解到 `~/Arduino/libraries`
- `arduino-offline/` 里的 core/工具链压缩包是**原始素材**，未自动接线
  （完整离线 core 安装尚未验证）；默认场景下 core 走 arduino-cli 在线安装
- 装好 core 之后，项目自己的编译命令完全离线可用

Release 附件：`esp32-core.zip`、`esp32s3-libs.zip`、`esptool.tar.gz`、
`xtensa-elf.tar.gz`、`xtensa-14.tar.gz`、`ubuntu-base.tar.gz`。
下载后放进 `arduino-offline/` 或按需使用。

## 红线（proot / 手机）

- proot Ubuntu **没有 USB 访问**：串口烧录只能在 Termux 原生层或 PC 上做，
  手机日常一律 OTA
- 首次烧录、改分区表、救砖仍需 PC 串口
- 不要把 `build.sh upload COMx` 当日常命令

---

## 开源协议

工具链脚本、文档：**MIT**，见 [LICENSE](LICENSE)。

`arduino-cli`、ESP32 core、Xtensa 工具链、各离线库等第三方二进制/源码
分别遵循各自上游许可证。
