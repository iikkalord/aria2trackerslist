#!/bin/bash
# 客户端一键脚本

VERSION="1.0.0"
REPO_URL="https://github.com/yourname/tracker-updater"
CONFIG_FILE="/etc/aria2/aria2.conf"

# 自动选择CDN
MIRRORS=(
    "https://raw.githubusercontent.com/yourname/tracker-updater/main/processed.txt"
    "https://cdn.jsdelivr.net/gh/yourname/tracker-updater/processed.txt"
)

# 安全下载函数
safe_fetch() {
    for url in "${MIRRORS[@]}"; do
        if curl -sSfL --connect-timeout 15 "$url" > /tmp/trackers.tmp; then
            grep -q 'udp://' /tmp/trackers.tmp && return 0
        fi
    done
    echo "所有镜像源不可用" >&2
    exit 1
}

# 主流程
if [ "$1" = "-v" ]; then
    echo "Tracker Updater $VERSION"
    exit
fi

safe_fetch

TRACKERS=$(< /tmp/trackers.tmp)
[ -n "$TRACKERS" ] || exit 1

# 备份配置
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# 更新配置
if grep -q "^bt-tracker=" "$CONFIG_FILE"; then
    sed -i "s|^bt-tracker=.*|bt-tracker=$TRACKERS|" "$CONFIG_FILE"
else
    echo "bt-tracker=$TRACKERS" >> "$CONFIG_FILE"
fi

# 服务管理
if which systemctl &> /dev/null; then
    systemctl try-restart aria2
elif which service &> /dev/null; then
    service aria2 restart
fi

echo "更新成功！当前Tracker数量: $(tr ',' '\n' <<< "$TRACKERS" | wc -l)"
