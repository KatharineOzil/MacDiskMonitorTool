磁盘空间监控脚本套装
====================

本目录包含三个监控脚本，适用于不同场景：

## 1. 原版脚本（需要fswatch）
文件：`disk_monitor.sh`
特点：事件驱动，CPU占用极低
依赖：fswatch（需通过Homebrew安装）
安装：`brew install fswatch`
使用：
```bash
# 添加执行权限
chmod +x ~/Desktop/disk_monitor.sh

# 监控/Users目录（默认）
~/Desktop/disk_monitor.sh

# 监控指定目录
~/Desktop/disk_monitor.sh /path/to/directory

# 指定日志文件
~/Desktop/disk_monitor.sh /Users ~/Desktop/custom_log.csv
```

## 2. 简化版脚本（无需依赖）
文件：`disk_monitor_simple.sh`
特点：使用find命令定期扫描，无需安装任何软件
缺点：CPU占用较高（每5秒扫描一次）
使用：
```bash
# 添加执行权限
chmod +x ~/Desktop/disk_monitor_simple.sh

# 监控/Users目录（默认）
~/Desktop/disk_monitor_simple.sh

# 监控指定目录
~/Desktop/disk_monitor_simple.sh /path/to/directory

# 指定日志文件和扫描间隔（默认5秒）
~/Desktop/disk_monitor_simple.sh /Users ~/Desktop/custom_log.csv 10
```

## 3. Python版脚本（需要watchdog库）
文件：`disk_monitor_python.py`
特点：事件驱动，CPU占用低，跨平台
依赖：Python3和watchdog库（已安装）
安装：`pip3 install watchdog`
使用：
```bash
# 添加执行权限
chmod +x ~/Desktop/disk_monitor_python.py

# 监控/Users目录（默认）
python3 ~/Desktop/disk_monitor_python.py

# 监控指定目录
python3 ~/Desktop/disk_monitor_python.py /path/to/directory

# 指定日志文件
python3 ~/Desktop/disk_monitor_python.py /Users ~/Desktop/custom_log.csv

# 指定事件处理延迟（默认1秒）
python3 ~/Desktop/disk_monitor_python.py /Users ~/Desktop/log.csv --latency 2.0
```

## 日志格式
所有脚本的日志格式均为CSV：
```
时间,文件路径,文件大小(字节),文件大小(可读),事件类型
```

## 推荐使用场景
1. **长期监控**：使用原版脚本（需要fswatch）或Python版脚本
2. **快速测试**：使用简化版脚本
3. **无网络环境**：使用简化版脚本
4. **跨平台需求**：使用Python版脚本

## 注意事项
1. **权限问题**：监控系统目录可能需要管理员权限
2. **磁盘空间**：日志文件会持续增长，定期清理
3. **性能影响**：
   - 原版和Python版：CPU占用极低
   - 简化版：CPU占用较高，适合短期监控
4. **macOS限制**：某些目录需要"Full Disk Access"权限

## 日志分析示例
```bash
# 查看最大的文件
sort -t, -k3 -n ~/Desktop/disk_monitor_python.log | tail -20

# 按文件类型统计
awk -F, '{print $2}' ~/Desktop/disk_monitor_python.log | grep -oE '\.[^.]+$' | sort | uniq -c | sort -rn

# 实时监控日志
tail -f ~/Desktop/disk_monitor_python.log

# 查看特定时间段的记录
grep "2026-06-10 12:" ~/Desktop/disk_monitor_python.log
```

## 故障排除
1. **fswatch安装失败**：确保已安装Command Line Tools：`xcode-select --install`
2. **watchdog安装失败**：使用`pip3 install --user watchdog`
3. **权限被拒绝**：在系统设置中授予终端"Full Disk Access"权限
4. **日志文件为空**：检查监控目录是否有文件创建事件

## 快速开始
推荐使用Python版脚本（已安装依赖）：
```bash
# 监控整个用户目录
python3 ~/Desktop/disk_monitor_python.py /Users

# 监控下载目录
python3 ~/Desktop/disk_monitor_python.py ~/Downloads

# 监控临时目录
python3 ~/Desktop/disk_monitor_python.py /tmp
```