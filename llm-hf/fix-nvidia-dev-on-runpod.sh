#!/bin/bash
# fix_nvidia_device.sh
# 检测容器实际拿到的 GPU 设备文件，创建 /dev/nvidia0 别名

set -e

echo "[nvidia-fix] 检查 /dev/nvidia* 设备文件..."

# 找到实际存在的 nvidia 设备（排除 nvidiactl/nvidia-uvm/nvidia-modeset）
ACTUAL_DEV=$(ls /dev/nvidia[0-9]* 2>/dev/null | head -1)

if [ -z "$ACTUAL_DEV" ]; then
    echo "[nvidia-fix] 未找到任何 nvidia 设备文件，跳过"
    exit 0
fi

if [ -e "/dev/nvidia0" ]; then
    echo "[nvidia-fix] /dev/nvidia0 已存在，无需处理"
else
    # 获取实际设备的 major:minor
    MAJOR=$(stat -c '%t' "$ACTUAL_DEV" | xargs printf '%d\n' 2>/dev/null || stat -c '%T' "$ACTUAL_DEV" | xargs -I{} printf '%d\n' {})
    MINOR=$(stat -c '%T' "$ACTUAL_DEV" | xargs printf '%d\n' 2>/dev/null)

    # 用十六进制转十进制（stat 输出是十六进制）
    MAJOR_DEC=$((16#$(stat -c '%t' "$ACTUAL_DEV")))
    MINOR_DEC=$((16#$(stat -c '%T' "$ACTUAL_DEV")))

    echo "[nvidia-fix] 检测到 $ACTUAL_DEV (major=$MAJOR_DEC, minor=$MINOR_DEC)"
    echo "[nvidia-fix] 创建 /dev/nvidia0 -> major=$MAJOR_DEC, minor=$MINOR_DEC"

    mknod -m 666 /dev/nvidia0 c "$MAJOR_DEC" "$MINOR_DEC"
    echo "[nvidia-fix] 创建成功"
fi