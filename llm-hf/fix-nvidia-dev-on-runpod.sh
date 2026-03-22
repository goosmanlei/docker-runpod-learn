#!/bin/bash
# fix-nvidia-dev-on-runpod.sh
# 检测容器实际拿到的 GPU 设备文件，确保 /dev/nvidia0 存在且 major:minor 正确

set -euo pipefail

echo "[nvidia-fix] 检查 /dev/nvidia* 设备文件..."

# 找到实际存在的 nvidia GPU 设备（排除 nvidiactl/nvidia-uvm/nvidia-modeset）
ACTUAL_DEV=$(ls /dev/nvidia[0-9]* 2>/dev/null | head -1 || true)

if [ -z "$ACTUAL_DEV" ]; then
    echo "[nvidia-fix] 未找到任何 nvidia 设备文件，跳过"
    exit 0
fi

# 获取实际设备的 major:minor（stat 输出十六进制，需转十进制）
MAJOR_DEC=$((16#$(stat -c '%t' "$ACTUAL_DEV")))
MINOR_DEC=$((16#$(stat -c '%T' "$ACTUAL_DEV")))
echo "[nvidia-fix] 检测到 $ACTUAL_DEV (major=$MAJOR_DEC, minor=$MINOR_DEC)"

# 如果 /dev/nvidia0 已存在，检查 major:minor 是否一致
if [ -e "/dev/nvidia0" ]; then
    EXIST_MAJOR=$((16#$(stat -c '%t' /dev/nvidia0)))
    EXIST_MINOR=$((16#$(stat -c '%T' /dev/nvidia0)))
    if [ "$EXIST_MAJOR" -eq "$MAJOR_DEC" ] && [ "$EXIST_MINOR" -eq "$MINOR_DEC" ]; then
        echo "[nvidia-fix] /dev/nvidia0 已存在且正确，无需处理"
        exit 0
    fi
    echo "[nvidia-fix] /dev/nvidia0 存在但 major:minor 不匹配（${EXIST_MAJOR}:${EXIST_MINOR} vs ${MAJOR_DEC}:${MINOR_DEC}），重建..."
    rm -f /dev/nvidia0
fi

mknod -m 666 /dev/nvidia0 c "$MAJOR_DEC" "$MINOR_DEC"
echo "[nvidia-fix] 创建 /dev/nvidia0 成功"
