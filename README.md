# 磁盘空间监控脚本套装

> 一套用于监控macOS磁盘空间使用情况的脚本工具，可追踪文件创建事件并记录详细信息，帮助用户快速定位磁盘空间消耗来源。

**[English Version](README_EN.md)** | **中文版本**

## 📁 项目结构

```
disk-monitor-project/
├── disk_monitor.sh          # 原版脚本（需要fswatch）
├── disk_monitor_simple.sh   # 简化版脚本（无需依赖）
├── disk_monitor_python.py   # Python版脚本（推荐）
├── disk_monitor_readme.txt  # 原始使用说明
├── disk_monitor_readme_all.txt # 综合说明文档
├── DESCRIPTION.md           # 项目简介（中文）
├── DESCRIPTION_EN.md        # 项目简介（英文）
├── README.md               # 本文件（中文）
└── README_EN.md            # 英文版说明
```

## 🚀 快速开始

### 推荐方案：Python版脚本（无需编译，已安装依赖）

```bash
# 监控整个用户目录
python3 disk_monitor_python.py /Users

# 监控下载目录
python3 disk_monitor_python.py ~/Downloads

# 监控临时目录
python3 disk_monitor_python.py /tmp
```

**日志文件说明：**
- 日志文件默认保存在脚本所在目录的 `log/` 子文件夹中，文件名包含开始运行的时间戳
- 例如：`log/disk_monitor_python_20260610_144200.log`
- `log/` 目录会自动创建，无需手动创建
- 当按 `Ctrl+C` 停止脚本时，会自动生成总结报告，按文件夹归类统计创建的文件大小

### 备选方案：简化版脚本（无需任何依赖）

```bash
# 监控/Users目录，每5秒扫描一次
./disk_monitor_simple.sh /Users

# 监控指定目录，每10秒扫描一次
./disk_monitor_simple.sh /path/to/directory ~/Desktop/log.csv 10
```

## 📊 脚本对比

| 脚本 | CPU占用 | 依赖 | 实时性 | 适用场景 |
|------|--------|------|--------|----------|
| `disk_monitor.sh` | 极低 | fswatch | 实时 | 长期监控 |
| `disk_monitor_simple.sh` | 高 | 无 | 5秒延迟 | 快速测试 |
| `disk_monitor_python.py` | 低 | watchdog | 实时 | **推荐使用** |

## 🔧 安装与配置

### 1. Python版脚本（推荐）

**依赖安装：**
```bash
pip3 install watchdog
```

**使用：**
```bash
# 添加执行权限
chmod +x disk_monitor_python.py

# 基本用法
python3 disk_monitor_python.py [监控目录] [日志文件] [--latency 延迟秒数]

# 示例
python3 disk_monitor_python.py /Users ~/Desktop/monitor.log --latency 2.0
```

### 2. 原版脚本（最佳性能）

**依赖安装：**
```bash
# 安装Homebrew（如未安装）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装fswatch
brew install fswatch
```

**使用：**
```bash
chmod +x disk_monitor.sh
./disk_monitor.sh [监控目录] [日志文件]
```

### 3. 简化版脚本（无需依赖）

```bash
chmod +x disk_monitor_simple.sh
./disk_monitor_simple.sh [监控目录] [日志文件] [扫描间隔秒数]
```

## 📝 日志格式

所有脚本生成CSV格式日志：

```csv
时间,文件路径,文件大小(字节),文件大小(可读),事件类型
2026-06-10 12:30:45,/Users/username/Downloads/file.pdf,1048576,1.00MB,创建
```

## 📊 总结报告

当按 `Ctrl+C` 停止脚本时，会自动生成总结报告，包含：
- 监控时间范围
- 创建文件总数和总大小（MB）
- 按文件夹归类的统计表格（大小统一为MB），显示每个文件夹中创建的文件数量和总大小

总结报告会追加到日志文件末尾，所有大小统一以 **MB** 显示：
```csv
文件夹路径,文件数量,总大小(字节),总大小(MB)
/Users/username/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support,3158,xxxxx,xx.xxMB
/Users/username/Library/Application Support/AddressBook/Metadata,628,xxxxx,xx.xxMB
/Users/username/Library/Preferences,112,xxxxx,xx.xxMB
/Users/username/Desktop,5,xxxxx,xx.xxMB
```

**归类逻辑（分段式）**：
- Containers 路径 → 截取前9段（区分应用+数据类型，如 `.../com.tencent.xinWeChat/Data/Library/Application Support`）
- Application Support 路径 → 截取前7段（如 `.../Application Support/AddressBook/Metadata`）
- Library 其他路径 → 截取前5段（如 `.../Library/Preferences`）
- 用户目录路径 → 截取前4段（如 `.../Desktop`）

## 📈 日志分析示例

```bash
# 查看最大的文件
sort -t, -k3 -n monitor.log | tail -20

# 按文件类型统计
awk -F, '{print $2}' monitor.log | grep -oE '\.[^.]+$' | sort | uniq -c | sort -rn

# 实时监控日志
tail -f monitor.log

# 查看特定时间段
grep "2026-06-10 12:" monitor.log

# 查看大于10MB的文件
awk -F, '$3 > 10485760' monitor.log
```

## ⚠️ 注意事项

### 权限设置
- 监控用户目录通常无需特殊权限
- 监控系统目录需要管理员权限：`sudo ./script.sh /`
- 某些目录需要"Full Disk Access"权限：
  1. 系统设置 → 隐私与安全性 → Full Disk Access
  2. 添加终端应用程序（Terminal.app或iTerm.app）

### 性能考虑
- **Python版和原版**：事件驱动，CPU占用极低，适合长期运行
- **简化版**：定期扫描，CPU占用较高，适合短期测试
- 日志文件会持续增长，建议定期清理或归档

### macOS兼容性
- 支持macOS 10.15及以上版本
- 某些系统目录受SIP保护，即使root也无法监控

## 🔍 故障排除

### 问题1：fswatch安装失败
```bash
# 确保已安装Command Line Tools
xcode-select --install

# 更新Homebrew
brew update

# 重新安装
brew install fswatch
```

### 问题2：watchdog安装失败
```bash
# 使用pip用户安装
pip3 install --user watchdog

# 或使用虚拟环境
python3 -m venv myenv
source myenv/bin/activate
pip3 install watchdog
```

### 问题3：日志文件为空
1. 检查监控目录是否有文件创建事件
2. 确认脚本有读取权限
3. 尝试监控具体目录而非整个磁盘

### 问题4：权限被拒绝
```bash
# 使用sudo运行
sudo ./disk_monitor_python.py /Applications

# 或授予Full Disk Access权限
```

## 🎯 使用场景

### 场景1：监控磁盘空间快速消耗
```bash
# 开机后立即运行
python3 disk_monitor_python.py /Users ~/Desktop/boot_monitor.log
```

### 场景2：监控特定应用程序
```bash
# 监控Chrome下载目录
python3 disk_monitor_python.py ~/Downloads/Google\ Chrome

# 监控Xcode缓存
python3 disk_monitor_python.py ~/Library/Developer/Xcode/DerivedData
```

### 场景3：临时监控测试
```bash
# 快速测试5分钟
timeout 300 ./disk_monitor_simple.sh /tmp ~/Desktop/test.log 2
```

## 📚 相关资源

- [fswatch官方文档](https://emcrisostomo.github.io/fswatch/)
- [watchdog官方文档](https://pythonhosted.org/watchdog/)
- [macOS文件系统事件编程指南](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/Introduction/Introduction.html)

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License - 详见LICENSE文件（如存在）

---

**提示**：对于大多数用户，推荐使用Python版脚本，它提供了最佳的性能和易用性平衡。