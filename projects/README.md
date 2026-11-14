# 项目接入

每个项目一个目录：`projects/<名字>/`，至少两个文件：

```
projects/<名字>/
├── project.sh      # 六行配置
└── <源码包>        # git bundle / tar.gz / 目录
```

`project.sh` 里能用的变量：

| 变量 | 说明 |
|---|---|
| `PROJECT_NAME` | 还原后的目录名 |
| `PROJECT_BUNDLE` | bundle 文件名、源码压缩包名或目录名 |
| `PROJECT_OVERLAY` | 可选，解压到源码根（未提交改动） |
| `PROJECT_CORE` | arduino-cli core，如 `esp32:esp32@3.3.6`、`arduino:avr` |
| `PROJECT_LIBS` | 空格分隔的库；`arduino-offline/<库>.tar.gz` 优先 |
| `PROJECT_EXTRA_FILES` | 每行 `源文件:目标目录`，补 `.gitignore` 挡掉的文件 |

运行：`./setup.sh <名字>`。源码会还原到 `projects/<名字>/src/<PROJECT_NAME>/`。

项目的 `build.sh` / `ota.sh` 不归工具链管 —— FQBN、分区表、烧录方式因项目而异。
