# Disk Space Monitoring Script Suite

> A set of script tools for monitoring macOS disk space usage, capable of tracking file creation events and recording detailed information to help users quickly identify sources of disk space consumption.

## 📁 Project Structure

```
disk-monitor-project/
├── disk_monitor.sh          # Original script (requires fswatch)
├── disk_monitor_simple.sh   # Simplified script (no dependencies)
├── disk_monitor_python.py   # Python script (recommended)
├── disk_monitor_readme.txt  # Original usage instructions
├── disk_monitor_readme_all.txt # Comprehensive documentation
├── disk_monitor_simple.log  # Sample test log
└── README.md               # This file
```

## 🚀 Quick Start

### Recommended: Python Script (No compilation required, dependencies installed)

```bash
# Monitor entire user directory
python3 disk_monitor_python.py /Users

# Monitor downloads directory
python3 disk_monitor_python.py ~/Downloads

# Monitor temporary directory
python3 disk_monitor_python.py /tmp
```

### Alternative: Simplified Script (No dependencies required)

```bash
# Monitor /Users directory, scan every 5 seconds
./disk_monitor_simple.sh /Users

# Monitor specific directory, scan every 10 seconds
./disk_monitor_simple.sh /path/to/directory ~/Desktop/log.csv 10
```

## 📊 Script Comparison

| Script | CPU Usage | Dependencies | Real-time | Use Case |
|--------|----------|--------------|-----------|----------|
| `disk_monitor.sh` | Very Low | fswatch | Real-time | Long-term monitoring |
| `disk_monitor_simple.sh` | High | None | 5s delay | Quick testing |
| `disk_monitor_python.py` | Low | watchdog | Real-time | **Recommended** |

## 🔧 Installation & Configuration

### 1. Python Script (Recommended)

**Install dependencies:**
```bash
pip3 install watchdog
```

**Usage:**
```bash
# Add execution permission
chmod +x disk_monitor_python.py

# Basic usage
python3 disk_monitor_python.py [monitor_directory] [log_file] [--latency delay_seconds]

# Example
python3 disk_monitor_python.py /Users ~/Desktop/monitor.log --latency 2.0
```

### 2. Original Script (Best Performance)

**Install dependencies:**
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install fswatch
brew install fswatch
```

**Usage:**
```bash
chmod +x disk_monitor.sh
./disk_monitor.sh [monitor_directory] [log_file]
```

### 3. Simplified Script (No dependencies)

```bash
chmod +x disk_monitor_simple.sh
./disk_monitor_simple.sh [monitor_directory] [log_file] [scan_interval_seconds]
```

## 📝 Log Format

All scripts generate CSV format logs:

```csv
Time,File Path,File Size (bytes),File Size (readable),Event Type
2026-06-10 12:30:45,/Users/username/Downloads/file.pdf,1048576,1.00MB,Created
```

## 📈 Log Analysis Examples

```bash
# View largest files
sort -t, -k3 -n monitor.log | tail -20

# Statistics by file type
awk -F, '{print $2}' monitor.log | grep -oE '\.[^.]+$' | sort | uniq -c | sort -rn

# Real-time log monitoring
tail -f monitor.log

# View specific time period
grep "2026-06-10 12:" monitor.log

# View files larger than 10MB
awk -F, '$3 > 10485760' monitor.log
```

## ⚠️ Important Notes

### Permission Settings
- Monitoring user directories usually requires no special permissions
- Monitoring system directories requires administrator privileges: `sudo ./script.sh /`
- Some directories require "Full Disk Access" permission:
  1. System Settings → Privacy & Security → Full Disk Access
  2. Add terminal application (Terminal.app or iTerm.app)

### Performance Considerations
- **Python and Original scripts**: Event-driven, very low CPU usage, suitable for long-term running
- **Simplified script**: Periodic scanning, higher CPU usage, suitable for short-term testing
- Log files will continue to grow, regular cleanup or archiving recommended

### macOS Compatibility
- Supports macOS 10.15 and later
- Some system directories are protected by SIP, cannot be monitored even with root access

## 🔍 Troubleshooting

### Issue 1: fswatch installation failed
```bash
# Ensure Command Line Tools are installed
xcode-select --install

# Update Homebrew
brew update

# Reinstall
brew install fswatch
```

### Issue 2: watchdog installation failed
```bash
# Use pip user installation
pip3 install --user watchdog

# Or use virtual environment
python3 -m venv myenv
source myenv/bin/activate
pip3 install watchdog
```

### Issue 3: Log file is empty
1. Check if the monitored directory has file creation events
2. Confirm the script has read permissions
3. Try monitoring specific directories instead of the entire disk

### Issue 4: Permission denied
```bash
# Run with sudo
sudo ./disk_monitor_python.py /Applications

# Or grant Full Disk Access permission
```

## 🎯 Use Cases

### Case 1: Monitor rapid disk space consumption
```bash
# Run immediately after boot
python3 disk_monitor_python.py /Users ~/Desktop/boot_monitor.log
```

### Case 2: Monitor specific applications
```bash
# Monitor Chrome downloads directory
python3 disk_monitor_python.py ~/Downloads/Google\ Chrome

# Monitor Xcode cache
python3 disk_monitor_python.py ~/Library/Developer/Xcode/DerivedData
```

### Case 3: Temporary monitoring test
```bash
# Quick test for 5 minutes
timeout 300 ./disk_monitor_simple.sh /tmp ~/Desktop/test.log 2
```

## 📚 Related Resources

- [fswatch Official Documentation](https://emcrisostomo.github.io/fswatch/)
- [watchdog Official Documentation](https://pythonhosted.org/watchdog/)
- [macOS File System Events Programming Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/Introduction/Introduction.html)

## 🤝 Contributing

Issues and Pull Requests are welcome!

## 📄 License

MIT License - See LICENSE file if present

---

**Tip**: For most users, the Python script is recommended as it provides the best balance of performance and ease of use.