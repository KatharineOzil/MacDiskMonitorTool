# Project Description

## Short Description (One sentence)
A set of script tools for monitoring macOS disk space usage, capable of tracking file creation events and recording detailed information to help users quickly identify sources of disk space consumption.

## Detailed Description (One paragraph)
This is a macOS disk space monitoring script suite containing three different versions of monitoring tools: the original script (based on fswatch event-driven with very low CPU usage), the simplified script (no dependencies, using find command for periodic scanning), and the Python script (based on watchdog library, event-driven and cross-platform). All scripts can monitor file creation events in real-time, record file paths, sizes, and timestamps, generate CSV format logs, and help users track the problem of rapid disk space consumption after booting. The project provides complete documentation, usage examples, and log analysis techniques, suitable for daily disk space monitoring, application behavior analysis, and system performance optimization.

## Technical Features
- **Multiple script versions**: Adapt to different environments and requirements
- **Event-driven monitoring**: Python and original scripts have very low CPU usage
- **Log recording**: CSV format, easy for subsequent analysis and processing
- **Cross-platform potential**: Python version can be easily adapted to other operating systems
- **Complete documentation**: Includes usage instructions, troubleshooting, and practical application scenarios

## Use Cases
1. **Disk space problem diagnosis**: Track the culprit of rapid space consumption after booting
2. **Application behavior monitoring**: Analyze file creation patterns of specific software
3. **System performance optimization**: Identify unnecessary file creation and temporary file accumulation
4. **Development debugging**: Monitor file system operations of applications
5. **Security auditing**: Detect abnormal file creation activities

## Usage Examples
```bash
# Monitor entire user directory
python3 disk_monitor_python.py /Users

# Monitor specific application directory
python3 disk_monitor_python.py ~/Library/Application\ Support/Google/Chrome

# Generate log file with timestamp
python3 disk_monitor_python.py /tmp ~/Desktop/monitor_$(date +%Y%m%d_%H%M%S).log
```