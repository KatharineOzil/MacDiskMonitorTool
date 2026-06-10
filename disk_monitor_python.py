#!/usr/bin/env python3
"""
磁盘空间监控脚本（Python版）
使用watchdog库实现事件驱动监控，CPU占用低
无需安装fswatch，只需Python3和watchdog库
"""

import os
import sys
import time
import datetime
import argparse
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class DiskMonitorHandler(FileSystemEventHandler):
    """文件系统事件处理器"""
    
    def __init__(self, log_file, monitor_dir):
        self.log_file = log_file
        self.monitor_dir = monitor_dir
        self.start_time = datetime.datetime.now()
        self.files = []  # 记录所有创建的文件信息 [(path, size), ...]
        
        # 初始化日志文件
        self._init_log_file()
        
    def _init_log_file(self):
        """初始化日志文件头部"""
        with open(self.log_file, 'w', encoding='utf-8') as f:
            f.write("=" * 40 + "\n")
            f.write("磁盘空间监控日志（Python版）\n")
            f.write("=" * 40 + "\n")
            f.write(f"脚本开始时间: {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"监控目录: {self.monitor_dir}\n")
            f.write("=" * 40 + "\n\n")
            f.write("时间,文件路径,文件大小(字节),文件大小(可读),事件类型\n")
    
    def _format_size(self, size_bytes):
        """将字节大小转换为可读格式"""
        if size_bytes >= 1073741824:
            return f"{size_bytes / 1073741824:.2f}GB"
        elif size_bytes >= 1048576:
            return f"{size_bytes / 1048576:.2f}MB"
        elif size_bytes >= 1024:
            return f"{size_bytes / 1024:.2f}KB"
        else:
            return f"{size_bytes}B"
    
    def on_created(self, event):
        """文件创建事件处理"""
        if event.is_directory:
            return
        
        try:
            # 获取文件信息
            file_path = event.src_path
            stat_info = os.stat(file_path)
            file_size = stat_info.st_size
            modify_time = datetime.datetime.fromtimestamp(stat_info.st_mtime)
            
            # 格式化大小
            readable_size = self._format_size(file_size)
            
            # 记录到日志
            current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            log_entry = f"{current_time},{file_path},{file_size},{readable_size},创建\n"
            
            with open(self.log_file, 'a', encoding='utf-8') as f:
                f.write(log_entry)
            
            # 记录到文件列表
            self.files.append((file_path, file_size))
            
            # 控制台输出
            print(f"[{current_time}] 新文件: {file_path} ({readable_size})")
            
        except (OSError, FileNotFoundError) as e:
            # 文件可能在事件触发后被删除
            pass

def generate_summary_report(event_handler, monitor_dir, log_file):
    """生成总结报告，按文件夹归类统计"""
    print("生成总结报告...")
    
    # 如果没有记录任何文件，直接返回
    if not event_handler.files:
        print("未记录到任何文件创建事件。")
        return
    
    # 按文件夹归类（往上层三个文件夹）
    def get_parent_n(path, n):
        """获取上n层目录"""
        for _ in range(n):
            path = os.path.dirname(path)
        return path
    
    folder_stats = {}  # {folder: {'count': 0, 'size': 0}}
    for file_path, file_size in event_handler.files:
        folder = get_parent_n(file_path, 3)  # 往上三层
        if folder not in folder_stats:
            folder_stats[folder] = {'count': 0, 'size': 0}
        folder_stats[folder]['count'] += 1
        folder_stats[folder]['size'] += file_size
    
    # 计算总大小
    total_size = sum(stats['size'] for stats in folder_stats.values())
    total_count = len(event_handler.files)
    
    # 生成可读大小
    def format_size(size_bytes):
        if size_bytes >= 1073741824:
            return f"{size_bytes / 1073741824:.2f}GB"
        elif size_bytes >= 1048576:
            return f"{size_bytes / 1048576:.2f}MB"
        elif size_bytes >= 1024:
            return f"{size_bytes / 1024:.2f}KB"
        else:
            return f"{size_bytes}B"
    
    # 写入总结报告到日志文件
    with open(log_file, 'a', encoding='utf-8') as f:
        f.write("\n")
        f.write("=" * 40 + "\n")
        f.write("总结报告\n")
        f.write("=" * 40 + "\n")
        f.write(f"监控时间: {event_handler.start_time.strftime('%Y-%m-%d %H:%M:%S')} 至 {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"监控目录: {monitor_dir}\n")
        f.write(f"创建文件总数: {total_count}\n")
        f.write(f"创建文件总大小: {total_size} 字节 ({format_size(total_size)})\n")
        f.write("\n按文件夹归类统计:\n")
        f.write("文件夹路径,文件数量,总大小(字节),总大小(可读)\n")
        for folder, stats in folder_stats.items():
            count = stats['count']
            size = stats['size']
            readable_size = format_size(size)
            f.write(f"{folder},{count},{size},{readable_size}\n")
    
    print("总结报告已生成。")

def main():
    # 获取脚本所在目录和开始时间戳
    script_dir = os.path.dirname(os.path.abspath(__file__))
    log_dir = os.path.join(script_dir, 'log')
    # 确保log目录存在
    os.makedirs(log_dir, exist_ok=True)
    start_time_stamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    default_log_file = os.path.join(log_dir, f'disk_monitor_python_{start_time_stamp}.log')
    
    parser = argparse.ArgumentParser(description='磁盘空间监控脚本（Python版）')
    parser.add_argument('monitor_dir', nargs='?', default='/Users',
                        help='监控目录路径（默认: /Users）')
    parser.add_argument('log_file', nargs='?', 
                        default=default_log_file,
                        help='日志文件路径（默认: 脚本目录下，文件名包含开始时间戳）')
    parser.add_argument('--latency', type=float, default=1.0,
                        help='事件处理延迟（秒，默认: 1.0）')
    
    args = parser.parse_args()
    
    # 检查监控目录是否存在
    if not os.path.exists(args.monitor_dir):
        print(f"错误: 监控目录不存在: {args.monitor_dir}")
        sys.exit(1)
    
    print("Python版磁盘监控脚本")
    print(f"脚本开始时间: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"监控目录: {args.monitor_dir}")
    print(f"日志文件: {args.log_file}")
    print(f"事件处理延迟: {args.latency}秒")
    print("")
    print("开始监控文件创建事件...")
    print("按Ctrl+C停止监控")
    print("")
    
    # 创建事件处理器和观察者
    event_handler = DiskMonitorHandler(args.log_file, args.monitor_dir)
    observer = Observer()
    observer.schedule(event_handler, args.monitor_dir, recursive=True)
    
    # 启动观察者
    observer.start()
    
    try:
        while True:
            time.sleep(args.latency)
    except KeyboardInterrupt:
        print("\n监控已停止。")
        # 生成总结报告
        generate_summary_report(event_handler, args.monitor_dir, args.log_file)
        observer.stop()
    
    observer.join()

if __name__ == '__main__':
    main()