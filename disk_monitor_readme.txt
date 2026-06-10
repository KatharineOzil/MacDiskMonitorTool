磁盘空间监控脚本使用说明
================================

1. 安装fswatch（如果尚未安装）
   打开终端，运行以下命令：
   ```
   brew install fswatch
   ```
   如果没有安装Homebrew，请先安装：
   ```
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. 赋予脚本执行权限
   在终端中运行：
   ```
   chmod +x ~/Desktop/disk_monitor.sh
   ```

3. 运行监控脚本
   ```
   # 监控/Users目录（默认）
   ~/Desktop/disk_monitor.sh
   
   # 监控指定目录
   ~/Desktop/disk_monitor.sh /path/to/directory
   
   # 指定日志文件路径
   ~/Desktop/disk_monitor.sh /Users ~/Desktop/custom_log.csv
   ```

4. 停止监控
   按 `Ctrl+C` 停止脚本。

5. 查看日志
   日志默认保存在 `~/Desktop/disk_monitor.log`
   日志格式为CSV，包含以下字段：
   - 时间：文件创建时间
   - 文件路径：完整路径
   - 文件大小(字节)：原始字节数
   - 文件大小(可读)：人类可读格式（KB/MB/GB）
   - 事件类型：创建

6. 性能说明
   - 使用fswatch基于事件的监控，CPU占用极低
   - 事件合并延迟2秒，减少重复事件
   - 排除了常见临时文件和缓存目录

7. 注意事项
   - 脚本需要监控目录的读取权限
   - 某些系统目录可能需要管理员权限
   - 日志文件会持续增长，定期清理或归档

8. 故障排除
   如果遇到"Operation not permitted"错误，可能需要授予Full Disk Access权限：
   - 系统设置 > 隐私与安全性 > Full Disk Access
   - 添加终端应用程序（Terminal.app或iTerm.app）

9. 备选方案（如果没有fswatch）
   如果无法安装fswatch，可以使用以下简单的定期扫描脚本：
   ```
   # 每30秒扫描一次/Users目录，记录新文件
   while true; do
     find /Users -type f -newer /tmp/last_scan 2>/dev/null | while read file; do
       echo "$(date),$(stat -f%z "$file"),$file" >> ~/Desktop/disk_scan.log
     done
     touch /tmp/last_scan
     sleep 30
   done
   ```
   注意：此方法CPU占用较高，不推荐长时间运行。