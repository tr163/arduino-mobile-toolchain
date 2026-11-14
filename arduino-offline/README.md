# 离线素材

`toolchain-setup.sh` 按项目声明的库名，优先从这里取离线包：

```
arduino-offline/<库名>.tar.gz   → 解压到 ~/Arduino/libraries/
```

压缩包顶层应是库目录本身（例如 `MyLib/`）。没有对应文件时回退到
`arduino-cli lib install <库名>`。

大体积 core / 工具链素材（ESP32 core、Xtensa 工具链、Ubuntu rootfs、esptool）
超出 GitHub 单文件 100 MB 限制，放在仓库 Releases 页面，按需下载：

- `esp32-core.zip`
- `esp32s3-libs.zip`
- `esptool.tar.gz`
- `xtensa-elf.tar.gz`
- `xtensa-14.tar.gz`
- `ubuntu-base.tar.gz`

这些是原始素材，目前未自动接线（完整离线 core 安装尚未验证）。
