#!/bin/bash

# 磁盘空间监控脚本
# 监控文件创建事件，记录文件位置、大小和时间
# 使用fswatch实现低CPU占用

set -e

# 配置参数
MONITOR_DIR="${1:-/Users}"  # 默认监控/Users目录，可通过参数指定
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"  # 脚本所在目录
START_TIME_STAMP=$(date "+%Y%m%d_%H%M%S")  # 开始时间戳，用于文件名
LOG_FILE="${2:-$SCRIPT_DIR/disk_monitor_${START_TIME_STAMP}.log}"  # 日志文件路径，默认在脚本目录下
LATENCY=2  # 事件合并延迟（秒），减少CPU占用

# 检查fswatch是否安装
if ! command -v fswatch &> /dev/null; then
    echo "错误: 未找到fswatch命令。"
    echo "请先安装fswatch："
    echo "  brew install fswatch"
    echo ""
    echo "如果没有安装Homebrew，请先安装Homebrew："
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# 记录脚本开始时间
START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "脚本开始时间: $START_TIME"
echo "监控目录: $MONITOR_DIR"
echo "日志文件: $LOG_FILE"
echo "事件合并延迟: ${LATENCY}秒"
echo ""

# 写入日志头部
{
    echo "========================================"
    echo "磁盘空间监控日志"
    echo "========================================"
    echo "脚本开始时间: $START_TIME"
    echo "监控目录: $MONITOR_DIR"
    echo "事件合并延迟: ${LATENCY}秒"
    echo "========================================"
    echo ""
    echo "时间,文件路径,文件大小(字节),文件大小(可读),事件类型"
} > "$LOG_FILE"

# 创建临时文件记录文件路径和大小
FILE_LIST=$(mktemp)
trap 'rm -f "$FILE_LIST"' EXIT

# 定义清理函数
cleanup() {
    echo ""
    echo "监控已停止。"
    echo "生成总结报告..."
    
    # 如果没有记录任何文件，直接退出
    if [[ ! -s "$FILE_LIST" ]]; then
        echo "未记录到任何文件创建事件。"
        echo "日志已保存到: $LOG_FILE"
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
        # 使用awk按文件夹归类
        awk '{
            folder = $1
            sub(/\/[^\/]*$/, "", folder)  # 提取文件夹部分
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
    exit 0
}

# 捕获中断信号
trap cleanup SIGINT SIGTERM

echo "开始监控文件创建事件..."
echo "按Ctrl+C停止监控"
echo ""

# 使用fswatch监控文件创建事件
# --event Created: 只监控创建事件
# --latency: 事件合并延迟，减少CPU占用
# --monitor kqueue: 使用kqueue监控器（macOS默认）
# --recursive: 递归监控子目录
# --exclude: 排除常见临时文件和缓存目录
fswatch \
    --event Created \
    --latency "$LATENCY" \
    --monitor kqueue \
    --recursive \
    --exclude '\.DS_Store' \
    --exclude '\.AppleDouble' \
    --exclude '\.LSOverride' \
    --exclude '\.Spotlight-V100' \
    --exclude '\.Trashes' \
    --exclude '\.fseventsd' \
    --exclude '\.TemporaryItems' \
    --exclude '\.VolumeIcon.icns' \
    --exclude 'com\.apple\.TimeMachine\.metadata' \
    --exclude '\.AppleDB$' \
    --exclude '\.AppleDesktop$' \
    --exclude '\.apdisk$' \
    --exclude '\.db$' \
    --exclude '\.sqlite$' \
    --exclude '\.sqlite-shm$' \
    --exclude '\.sqlite-wal$' \
    --exclude '\.log$' \
    --exclude '\.tmp$' \
    --exclude '\.temp$' \
    --exclude '\.swp$' \
    --exclude '\.swo$' \
    --exclude '\.pyc$' \
    --exclude '\.pyo$' \
    --exclude '\.class$' \
    --exclude '\.o$' \
    --exclude '\.obj$' \
    --exclude '\.exe$' \
    --exclude '\.dll$' \
    --exclude '\.so$' \
    --exclude '\.dylib$' \
    --exclude '\.app$' \
    --exclude '\.bundle$' \
    --exclude '\.framework$' \
    --exclude '\.xcodeproj$' \
    --exclude '\.xcworkspace$' \
    --exclude '\.git$' \
    --exclude '\.svn$' \
    --exclude '\.hg$' \
    --exclude '\.bzr$' \
    --exclude '\.npm$' \
    --exclude '\.yarn$' \
    --exclude '\.pnpm$' \
    --exclude '\.node_modules$' \
    --exclude '\.venv$' \
    --exclude '\.env$' \
    --exclude '\.tox$' \
    --exclude '\.mypy_cache$' \
    --exclude '\.pytest_cache$' \
    --exclude '\.coverage$' \
    --exclude '\.htmlcov$' \
    --exclude '\.cache$' \
    --exclude '\.gradle$' \
    --exclude '\.m2$' \
    --exclude '\.cargo$' \
    --exclude '\.rustup$' \
    --exclude '\.rbenv$' \
    --exclude '\.rvm$' \
    --exclude '\.nvm$' \
    --exclude '\.sdkman$' \
    --exclude '\.jenv$' \
    --exclude '\.pyenv$' \
    --exclude '\.nodenv$' \
    --exclude '\.volta$' \
    --exclude '\.fnm$' \
    --exclude '\.rtx$' \
    --exclude '\.asdf$' \
    --exclude '\.mise$' \
    --exclude '\.direnv$' \
    --exclude '\.envrc$' \
    --exclude '\.editorconfig$' \
    --exclude '\.prettierrc$' \
    --exclude '\.eslintrc$' \
    --exclude '\.stylelintrc$' \
    --exclude '\.babelrc$' \
    --exclude '\.postcssrc$' \
    --exclude '\.browserslistrc$' \
    --exclude '\.npmrc$' \
    --exclude '\.yarnrc$' \
    --exclude '\.pnpmrc$' \
    --exclude '\.nvmrc$' \
    --exclude '\.node-version$' \
    --exclude '\.python-version$' \
    --exclude '\.ruby-version$' \
    --exclude '\.java-version$' \
    --exclude '\.go-version$' \
    --exclude '\.rust-version$' \
    --exclude '\.swift-version$' \
    --exclude '\.php-version$' \
    --exclude '\.perl-version$' \
    --exclude '\.lua-version$' \
    --exclude '\.r-version$' \
    --exclude '\.scala-version$' \
    --exclude '\.kotlin-version$' \
    --exclude '\.clojure-version$' \
    --exclude '\.elixir-version$' \
    --exclude '\.erlang-version$' \
    --exclude '\.haskell-version$' \
    --exclude '\.ocaml-version$' \
    --exclude '\.racket-version$' \
    --exclude '\.scheme-version$' \
    --exclude '\.clisp-version$' \
    --exclude '\.sbcl-version$' \
    --exclude '\.ccl-version$' \
    --exclude '\.ecl-version$' \
    --exclude '\.abcl-version$' \
    --exclude '\.cmucl-version$' \
    --exclude '\.clisp-version$' \
    --exclude '\.gcl-version$' \
    --exclude '\.acl2-version$' \
    --exclude '\.maxima-version$' \
    --exclude '\.macsyma-version$' \
    --exclude '\.reduce-version$' \
    --exclude '\.formac-version$' \
    --exclude '\.scratchpad-version$' \
    --exclude '\.mathematica-version$' \
    --exclude '\.matlab-version$' \
    --exclude '\.maple-version$' \
    --exclude '\.mathcad-version$' \
    --exclude '\.sage-version$' \
    --exclude '\.gap-version$' \
    --exclude '\.magma-version$' \
    --exclude '\.pari-version$' \
    --exclude '\.singular-version$' \
    --exclude '\.macaulay2-version$' \
    --exclude '\.coq-version$' \
    --exclude '\.agda-version$' \
    --exclude '\.idris-version$' \
    --exclude '\.lean-version$' \
    --exclude '\.isabelle-version$' \
    --exclude '\.hol-version$' \
    --exclude '\.pvs-version$' \
    --exclude '\.acl2-version$' \
    --exclude '\.nuprl-version$' \
    --exclude '\.metamath-version$' \
    --exclude '\.mizar-version$' \
    --exclude '\.qed-version$' \
    --exclude '\.proofpower-version$' \
    --exclude '\.hol-light-version$' \
    --exclude '\.hol4-version$' \
    --exclude '\.hol98-version$' \
    --exclude '\.hol90-version$' \
    --exclude '\.hol88-version$' \
    --exclude '\.hol73-version$' \
    --exclude '\.hol70-version$' \
    --exclude '\.lcf-version$' \
    --exclude '\.lcf-prolog-version$' \
    --exclude '\.lcf-ml-version$' \
    --exclude '\.lcf-lisp-version$' \
    --exclude '\.lcf-scheme-version$' \
    --exclude '\.lcf-clojure-version$' \
    --exclude '\.lcf-elisp-version$' \
    --exclude '\.lcf-common-lisp-version$' \
    --exclude '\.lcf-racket-version$' \
    --exclude '\.lcf-scheme-version$' \
    --exclude '\.lcf-guile-version$' \
    --exclude '\.lcf-chicken-version$' \
    --exclude '\.lcf-gambit-version$' \
    --exclude '\.lcf-mit-scheme-version$' \
    --exclude '\.lcf-stalin-version$' \
    --exclude '\.lcf-vicare-version$' \
    --exclude '\.lcf-larceny-version$' \
    --exclude '\.lcf-chez-version$' \
    --exclude '\.lcf-ironscheme-version$' \
    --exclude '\.lcf-bigloo-version$' \
    --exclude '\.lcf-kawa-version$' \
    --exclude '\.lcf-sisc-version$' \
    --exclude '\.lcf-guile-version$' \
    --exclude '\.lcf-chicken-version$' \
    --exclude '\.lcf-gambit-version$' \
    --exclude '\.lcf-mit-scheme-version$' \
    --exclude '\.lcf-stalin-version$' \
    --exclude '\.lcf-vicare-version$' \
    --exclude '\.lcf-larceny-version$' \
    --exclude '\.lcf-chez-version$' \
    --exclude '\.lcf-ironscheme-version$' \
    --exclude '\.lcf-bigloo-version$' \
    --exclude '\.lcf-kawa-version$' \
    --exclude '\.lcf-sisc-version$' \
    --exclude '\.lcf-guile-version$' \
    --exclude '\.lcf-chicken-version$' \
    --exclude '\.lcf-gambit-version$' \
    --exclude '\.lcf-mit-scheme-version$' \
    --exclude '\.lcf-stalin-version$' \
    --exclude '\.lcf-vicare-version$' \
    --exclude '\.lcf-larceny-version$' \
    --exclude '\.lcf-chez-version$' \
    --exclude '\.lcf-ironscheme-version$' \
    --exclude '\.lcf-bigloo-version$' \
    --exclude '\.lcf-kawa-version$' \
    --exclude '\.lcf-sisc-version$' \
    "$MONITOR_DIR" | while read -r file_path; do
    
    # 检查文件是否存在（可能是临时文件已删除）
    if [[ ! -e "$file_path" ]]; then
        continue
    fi
    
    # 检查是否为文件（不是目录）
    if [[ -f "$file_path" ]]; then
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
        echo "$(date "+%Y-%m-%d %H:%M:%S"),$file_path,$file_size,$readable_size,创建" >> "$LOG_FILE"
        # 记录到文件列表，用于退出时总结
        echo "$file_path $file_size" >> "$FILE_LIST"
        
        # 控制台输出（可选）
        echo "[$(date "+%H:%M:%S")] 新文件: $file_path ($readable_size)"
    fi
done

# 如果fswatch退出，清理
cleanup