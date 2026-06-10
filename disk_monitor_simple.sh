#!/bin/bash

# 磁盘空间监控脚本（简化版）
# 使用find命令定期扫描，无需fswatch
# 适合快速测试，CPU占用较高

set -e

# 配置参数
MONITOR_DIR="${1:-/Users}"  # 默认监控/Users目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"  # 脚本所在目录
LOG_DIR="$SCRIPT_DIR/log"  # 日志目录
mkdir -p "$LOG_DIR"  # 确保日志目录存在
START_TIME_STAMP=$(date "+%Y%m%d_%H%M%S")  # 开始时间戳，用于文件名
LOG_FILE="${2:-$LOG_DIR/disk_monitor_simple_${START_TIME_STAMP}.log}"
SCAN_INTERVAL=5  # 扫描间隔（秒）

# 记录脚本开始时间
START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "简化版磁盘监控脚本"
echo "脚本开始时间: $START_TIME"
echo "监控目录: $MONITOR_DIR"
echo "日志文件: $LOG_FILE"
echo "扫描间隔: ${SCAN_INTERVAL}秒"
echo ""

# 写入日志头部
{
    echo "========================================"
    echo "磁盘空间监控日志（简化版）"
    echo "========================================"
    echo "脚本开始时间: $START_TIME"
    echo "监控目录: $MONITOR_DIR"
    echo "扫描间隔: ${SCAN_INTERVAL}秒"
    echo "========================================"
    echo ""
    echo "扫描时间,文件路径,文件大小(字节),文件大小(可读),修改时间"
} > "$LOG_FILE"

# 创建临时文件记录文件路径和大小
FILE_LIST=$(mktemp)
# 创建临时文件记录已扫描的文件
SCANDB=$(mktemp)

# 定义清理函数，生成总结报告并清理临时文件
cleanup() {
    echo ""
    echo "监控已停止。"
    echo "生成总结报告..."
    
    # 如果没有记录任何文件，直接退出
    if [[ ! -s "$FILE_LIST" ]]; then
        echo "未记录到任何文件创建事件。"
        echo "日志已保存到: $LOG_FILE"
        rm -f "$FILE_LIST" "$SCANDB"
        exit 0
    fi
    
    # 写入总结报告到日志文件
    {
        echo ""
        echo "========================================"
        echo "总结报告"
        echo "========================================"
        echo "监控时间: $START_TIME 至 $(date "+%Y-%m-%d %H:%M:%S")"
        echo "监控目录: $MONITOR_DIR"
        echo "创建文件总数: $(wc -l < "$FILE_LIST")"
        echo "创建文件总大小: $(awk '{sum+=$2} END {print sum}' "$FILE_LIST") 字节"
        echo ""
        echo "按文件夹归类统计:"
        echo "文件夹路径,文件数量,总大小(字节),总大小(可读)"
        # 使用awk按文件夹归类（往上层三个文件夹）
        awk '{
            path = $1
            # 移除文件名，获取文件夹路径
            sub(/\/[^\/]*$/, "", path)
            # 按 "/" 分割路径
            n = split(path, parts, "/")
            # 获取上三层文件夹（如果路径深度足够）
            if (n >= 3) {
                folder = parts[1] "/" parts[2] "/" parts[3]
                # 如果 parts[1] 是空字符串（根目录），需要调整
                if (parts[1] == "") {
                    folder = "/" parts[2] "/" parts[3]
                }
            } else {
                folder = path
            }
            sizes[folder] += $2
            counts[folder]++
        }
        END {
            for (folder in sizes) {
                size = sizes[folder]
                count = counts[folder]
                # 转换为可读格式
                if (size >= 1073741824) {
                    readable = sprintf("%.2fGB", size/1073741824)
                } else if (size >= 1048576) {
                    readable = sprintf("%.2fMB", size/1048576)
                } else if (size >= 1024) {
                    readable = sprintf("%.2fKB", size/1024)
                } else {
                    readable = size "B"
                }
                printf "%s,%d,%d,%s\n", folder, count, size, readable
            }
        }' "$FILE_LIST"
    } >> "$LOG_FILE"
    
    echo "总结报告已生成。"
    echo "日志已保存到: $LOG_FILE"
    rm -f "$FILE_LIST" "$SCANDB"
    exit 0
}

trap cleanup SIGINT SIGTERM
trap 'rm -f "$FILE_LIST" "$SCANDB"' EXIT

# 初始化：记录当前所有文件
echo "初始化扫描..."
find "$MONITOR_DIR" -type f 2>/dev/null > "$SCANDB"
echo "初始化完成，共记录 $(wc -l < "$SCANDB") 个文件"
echo "开始监控新文件创建..."
echo "按Ctrl+C停止监控"
echo ""

# 监控循环
while true; do
    # 扫描当前文件
    CURRENT_FILES=$(mktemp)
    find "$MONITOR_DIR" -type f 2>/dev/null > "$CURRENT_FILES"
    
    # 查找新文件
    NEW_FILES=$(comm -13 <(sort "$SCANDB") <(sort "$CURRENT_FILES"))
    
    # 如果有新文件
    if [[ -n "$NEW_FILES" ]]; then
        while IFS= read -r file_path; do
            # 跳过空行
            [[ -z "$file_path" ]] && continue
            
            # 检查文件是否存在
            [[ ! -e "$file_path" ]] && continue
            
            # 获取文件信息
            file_size=$(stat -f%z "$file_path" 2>/dev/null || echo "0")
            file_time=$(stat -f"%Sm" -t"%Y-%m-%d %H:%M:%S" "$file_path" 2>/dev/null || echo "未知")
            
            # 转换文件大小为可读格式
            if [[ "$file_size" -ge 1073741824 ]]; then
                readable_size=$(echo "scale=2; $file_size/1073741824" | bc 2>/dev/null || echo "$file_size")
                readable_size="${readable_size}GB"
            elif [[ "$file_size" -ge 1048576 ]]; then
                readable_size=$(echo "scale=2; $file_size/1048576" | bc 2>/dev/null || echo "$file_size")
                readable_size="${readable_size}MB"
            elif [[ "$file_size" -ge 1024 ]]; then
                readable_size=$(echo "scale=2; $file_size/1024" | bc 2>/dev/null || echo "$file_size")
                readable_size="${readable_size}KB"
            else
                readable_size="${file_size}B"
            fi
            
            # 记录到日志
            echo "$(date "+%Y-%m-%d %H:%M:%S"),$file_path,$file_size,$readable_size,$file_time" >> "$LOG_FILE"
            # 记录到文件列表，用于退出时总结
            echo "$file_path $file_size" >> "$FILE_LIST"
            
            # 控制台输出
            echo "[$(date "+%H:%M:%S")] 新文件: $file_path ($readable_size)"
        done <<< "$NEW_FILES"
    fi
    
    # 更新扫描数据库
    mv "$CURRENT_FILES" "$SCANDB"
    
    # 等待下一次扫描
    sleep "$SCAN_INTERVAL"
done