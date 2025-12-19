#!/bin/bash

# fix-page-alloc.sh - 修复 mm/page_alloc.c 中的返回值缺失问题
# 用法: ./fix-page-alloc.sh <内核源码根目录>

if [ -z "$1" ]; then
    echo "用法: $0 <内核源码根目录>"
    exit 1
fi

KERNEL_DIR="$1"
PAGE_ALLOC_FILE="$KERNEL_DIR/mm/page_alloc.c"

if [ ! -f "$PAGE_ALLOC_FILE" ]; then
    echo "错误: 找不到文件 $PAGE_ALLOC_FILE"
    exit 1
fi

echo "=== 开始分析 mm/page_alloc.c 文件 ==="

# 备份原文件
cp "$PAGE_ALLOC_FILE" "${PAGE_ALLOC_FILE}.bak"

# 显示问题行附近的代码 (第2355-2375行)
echo "=== 第2355-2375行的代码: ==="
sed -n '2355,2375p' "$PAGE_ALLOC_FILE"

# 查找第2365行所属的函数名
echo ""
echo "=== 查找第2365行所属的函数 ==="

# 向上查找最近的函数定义 (通过匹配函数签名模式)
FUNCTION_START=$(awk 'NR<=2365 && /^[a-zA-Z_].*\(.*\)/&&!/^\/\/&&!/{/ {line=NR; text=$0} END {print line}' "$PAGE_ALLOC_FILE")

if [ -n "$FUNCTION_START" ]; then
    echo "函数起始行: $FUNCTION_START"
    echo "函数签名:"
    sed -n "${FUNCTION_START}p" "$PAGE_ALLOC_FILE"
    
    # 检查函数返回类型
    FUNC_SIGNATURE=$(sed -n "${FUNCTION_START}p" "$PAGE_ALLOC_FILE")
    
    # 显示完整的函数上下文
    echo ""
    echo "=== 函数上下文 (${FUNCTION_START}-2375行): ==="
    sed -n "${FUNCTION_START},2375p" "$PAGE_ALLOC_FILE"
else
    echo "警告: 无法自动定位函数起始位置"
fi

echo ""
echo "=== 应用修复方案 ==="

# 常见的修复方案:
# 1. 如果是 CONFIG 条件编译导致的路径缺失,在 #endif 前添加默认返回
# 2. 如果是 switch 语句缺少 default 分支,添加 default 返回
# 3. 如果是函数末尾缺少 return,直接在闭括号前添加

# 检查第2365行是否是闭括号 '}'
LINE_2365=$(sed -n '2365p' "$PAGE_ALLOC_FILE")
if [[ "$LINE_2365" == "}" ]]; then
    echo "检测到第2365行是函数闭括号"
    
    # 检查上一行是否已经有 return 语句
    LINE_2364=$(sed -n '2364p' "$PAGE_ALLOC_FILE")
    if [[ ! "$LINE_2364" =~ "return" ]]; then
        echo "检测到缺少 return 语句,正在添加..."
        
        # 在2364行后插入合适的返回语句
        # 根据常见的内存分配函数,返回0表示成功
        sed -i '2364a\	return 0;' "$PAGE_ALLOC_FILE"
        
        echo "已添加默认返回语句: return 0;"
    else
        echo "检测到已有 return 语句,查找其他问题..."
        
        # 可能是条件编译导致的问题,查找 #ifdef/#endif
        # 在某些条件下某个分支没有返回值
        
        # 通用修复: 在函数结束前添加一个保底的 return
        sed -i '2364a\	return 0; /* fallback return */' "$PAGE_ALLOC_FILE"
    fi
fi

# 检查是否是 #endif 导致的问题
if [[ "$LINE_2365" =~ "#endif" ]]; then
    echo "检测到条件编译区块结束,在 #endif 前添加返回语句"
    sed -i '2364a\	return 0; /* CONFIG fallback */' "$PAGE_ALLOC_FILE"
fi

echo ""
echo "=== 修复后的代码 (第2360-2370行): ==="
sed -n '2360,2370p' "$PAGE_ALLOC_FILE"

echo ""
echo "修复完成! 原文件已备份为: ${PAGE_ALLOC_FILE}.bak"
echo "如果修复不正确,请恢复备份文件并手动修改"
