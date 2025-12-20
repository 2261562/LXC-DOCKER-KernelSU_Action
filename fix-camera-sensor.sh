#!/bin/bash

# fix-camera-sensor.sh - 修复相机传感器驱动中的变量作用域错误
# 用法: ./fix-camera-sensor.sh <内核源码根目录>

if [ -z "$1" ]; then
    echo "用法: $0 <内核源码根目录>"
    exit 1
fi

KERNEL_DIR="$1"
CAM_SENSOR_FILE="$KERNEL_DIR/techpack/camera/drivers/cam_sensor_module/cam_sensor_utils/cam_sensor_util.c"

if [ ! -f "$CAM_SENSOR_FILE" ]; then
    echo "错误: 找不到文件 $CAM_SENSOR_FILE"
    exit 1
fi

echo "=== 开始分析相机传感器驱动文件 ==="

# 备份原文件
cp "$CAM_SENSOR_FILE" "${CAM_SENSOR_FILE}.bak"

# 显示问题行附近的代码
echo "=== 第2470-2485行的代码: ==="
sed -n '2470,2485p' "$CAM_SENSOR_FILE"

echo ""
echo "=== 查找函数上下文 ==="

# 向上查找包含该行的函数
FUNCTION_START=$(awk 'NR<=2477 && /^[a-zA-Z_].*\(.*\)/ && !/^\/\// && !/{/ {line=NR; text=$0} END {print line}' "$CAM_SENSOR_FILE")

if [ -n "$FUNCTION_START" ]; then
    echo "函数起始行: $FUNCTION_START"
    FUNC_NAME=$(sed -n "${FUNCTION_START}p" "$CAM_SENSOR_FILE" | sed 's/(.*//' | awk '{print $NF}')
    echo "函数名: $FUNC_NAME"
    
    # 显示函数上下文 (前后50行)
    echo ""
    echo "=== 函数上下文 (2400-2500行): ==="
    sed -n '2400,2500p' "$CAM_SENSOR_FILE" | nl -ba -v 2400
fi

echo ""
echo "=== 查找可能的变量定义 ==="

# 在函数内查找 power_setting 相关的变量定义
echo "查找包含 'power_setting' 的所有行..."
grep -n "power_setting" "$CAM_SENSOR_FILE" | head -20

echo ""
echo "=== 应用修复 ==="

# 检查第2477行的实际内容
LINE_2477=$(sed -n '2477p' "$CAM_SENSOR_FILE")
echo "第2477行原内容: $LINE_2477"

# 检查附近是否有 ps 变量定义
if grep -q "struct.*power_setting.*\*ps" <(sed -n '2400,2500p' "$CAM_SENSOR_FILE"); then
    echo "检测到 ps 变量定义,使用 ps 替换 power_setting"
    sed -i '2477s/power_setting/ps/g' "$CAM_SENSOR_FILE"
elif grep -q "power_setting_array" <(sed -n '2400,2500p' "$CAM_SENSOR_FILE"); then
    echo "检测到 power_setting_array,可能需要使用数组访问"
    # 可能需要更复杂的替换逻辑
    sed -i '2477s/power_setting/power_setting_array/g' "$CAM_SENSOR_FILE"
else
    # 默认尝试使用 ps
    echo "未找到明确的变量定义,默认使用 ps"
    sed -i '2477s/power_setting/ps/g' "$CAM_SENSOR_FILE"
fi

echo ""
echo "=== 修复后的代码 (2470-2485行): ==="
sed -n '2470,2485p' "$CAM_SENSOR_FILE"

echo ""
echo "修复完成! 原文件已备份为: ${CAM_SENSOR_FILE}.bak"
