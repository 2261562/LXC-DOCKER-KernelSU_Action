#!/bin/bash

# fix_k30pro_config.sh - 为k30pro/一加9R内核源码添加必要配置
# 该脚本会在内核配置文件末尾添加必要的配置项

# 检查是否提供了配置文件路径参数
if [ -z "$1" ]; then
  echo "用法: $0 <内核配置文件路径>"
  exit 1
fi

CONFIG_FILE="$1"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
  echo "错误: 配置文件 $CONFIG_FILE 不存在"
  exit 1
fi

echo "正在检查并添加k30pro/一加9R必需的配置到 $CONFIG_FILE..."

# 检查是否已经存在这些配置
if grep -q "CONFIG_BUILD_ARM64_KERNEL_COMPRESSION_GZIP" "$CONFIG_FILE" && \
   grep -q "CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE" "$CONFIG_FILE" && \
   grep -q "CONFIG_BUILD_ARM64_DT_OVERLAY" "$CONFIG_FILE"; then
  echo "检测到必需的配置已存在，跳过添加"
  exit 0
fi

echo "正在添加k30pro/一加9R必需的配置..."

# 添加k30pro/一加9R必需的配置
cat << EOF >> "$CONFIG_FILE"

# k30pro/一加9R必需的配置
CONFIG_BUILD_ARM64_KERNEL_COMPRESSION_GZIP=y
CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE=y
CONFIG_BUILD_ARM64_DT_OVERLAY=y
EOF

echo "配置已成功添加到 $CONFIG_FILE"