#!/bin/bash
# 内核拼接工具
# 用于验证和拼接自编译内核与原厂 kernel-dtb

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  内核拼接工具 - Redmi Note 12 5G"
echo "========================================"
echo ""

# 检查参数
if [ "$#" -lt 1 ]; then
    echo "用法:"
    echo "  $0 verify <原厂kernel> <原厂kernel-dtb>  # 验证原厂文件"
    echo "  $0 merge <自编译Image> <原厂kernel-dtb>  # 拼接内核"
    echo "  $0 check-version <自编译Image> <原厂kernel>  # 检查版本是否匹配"
    echo ""
    echo "示例:"
    echo "  $0 verify kernel kernel-dtb"
    echo "  $0 merge Image kernel-dtb"
    echo "  $0 check-version Image kernel"
    exit 1
fi

ACTION=$1

# 从内核镜像中提取版本字符串
extract_kernel_version() {
    local KERNEL_FILE=$1
    local VERSION=""
    
    # 方法1: 使用 strings 搜索 Linux version
    VERSION=$(strings "$KERNEL_FILE" 2>/dev/null | grep -oE "Linux version [0-9]+\.[0-9]+\.[0-9]+[^ ]*" | head -1)
    
    if [ -z "$VERSION" ]; then
        # 方法2: 搜索更宽松的版本模式
        VERSION=$(strings "$KERNEL_FILE" 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+-[a-zA-Z0-9._-]+" | head -1)
    fi
    
    echo "$VERSION"
}

# 检查版本功能
check_version() {
    local NEW_IMAGE=$1
    local STOCK_KERNEL=$2
    
    if [ ! -f "$NEW_IMAGE" ]; then
        echo -e "${RED}错误: 找不到 $NEW_IMAGE${NC}"
        exit 1
    fi
    
    if [ ! -f "$STOCK_KERNEL" ]; then
        echo -e "${RED}错误: 找不到 $STOCK_KERNEL${NC}"
        exit 1
    fi
    
    echo "=== 提取内核版本 ==="
    echo ""
    
    NEW_VERSION=$(extract_kernel_version "$NEW_IMAGE")
    STOCK_VERSION=$(extract_kernel_version "$STOCK_KERNEL")
    
    echo "自编译内核: $NEW_VERSION"
    echo "原厂内核:   $STOCK_VERSION"
    echo ""
    
    if [ -z "$NEW_VERSION" ]; then
        echo -e "${YELLOW}⚠ 无法从自编译内核提取版本${NC}"
    fi
    
    if [ -z "$STOCK_VERSION" ]; then
        echo -e "${YELLOW}⚠ 无法从原厂内核提取版本${NC}"
    fi
    
    if [ -n "$NEW_VERSION" ] && [ -n "$STOCK_VERSION" ]; then
        # 提取主版本号 (如 5.4.210)
        NEW_MAIN=$(echo "$NEW_VERSION" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
        STOCK_MAIN=$(echo "$STOCK_VERSION" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
        
        echo "=== 版本比较 ==="
        echo "自编译主版本: $NEW_MAIN"
        echo "原厂主版本:   $STOCK_MAIN"
        echo ""
        
        if [ "$NEW_MAIN" = "$STOCK_MAIN" ]; then
            echo -e "${GREEN}✓ 主版本号匹配！${NC}"
            
            # 检查完整版本
            if [ "$NEW_VERSION" = "$STOCK_VERSION" ]; then
                echo -e "${GREEN}✓ 完整版本号完全匹配！WiFi 模块应该能正常加载${NC}"
            else
                echo -e "${YELLOW}⚠ 完整版本有差异，WiFi 模块可能无法加载${NC}"
                echo ""
                echo "建议: 修改 LOCALVERSION 使版本完全一致"
                
                # 提取 localversion
                STOCK_LOCAL=$(echo "$STOCK_VERSION" | sed "s/Linux version $STOCK_MAIN//")
                echo "原厂 LOCALVERSION: $STOCK_LOCAL"
            fi
        else
            echo -e "${RED}✗ 主版本号不匹配！${NC}"
            echo "WiFi 模块肯定无法加载"
            echo ""
            echo "你需要找到与原厂版本 ($STOCK_MAIN) 匹配的内核源码"
        fi
    fi
    
    echo ""
    echo "=== 详细版本字符串 ==="
    echo "自编译:"
    strings "$NEW_IMAGE" 2>/dev/null | grep -E "Linux version|vermagic" | head -3
    echo ""
    echo "原厂:"
    strings "$STOCK_KERNEL" 2>/dev/null | grep -E "Linux version|vermagic" | head -3
}

# 验证功能
verify_kernel() {
    KERNEL_FILE=$1
    KERNEL_DTB_FILE=$2
    
    if [ ! -f "$KERNEL_FILE" ]; then
        echo -e "${RED}错误: 找不到 $KERNEL_FILE${NC}"
        exit 1
    fi
    
    if [ ! -f "$KERNEL_DTB_FILE" ]; then
        echo -e "${RED}错误: 找不到 $KERNEL_DTB_FILE${NC}"
        exit 1
    fi
    
    echo "=== 文件信息 ==="
    KERNEL_SIZE=$(stat -f%z "$KERNEL_FILE" 2>/dev/null || stat -c%s "$KERNEL_FILE")
    DTB_SIZE=$(stat -f%z "$KERNEL_DTB_FILE" 2>/dev/null || stat -c%s "$KERNEL_DTB_FILE")
    
    KERNEL_SIZE_MB=$((KERNEL_SIZE / 1024 / 1024))
    DTB_SIZE_MB=$((DTB_SIZE / 1024 / 1024))
    
    echo "kernel:     ${KERNEL_SIZE_MB}MB ($KERNEL_SIZE bytes)"
    echo "kernel-dtb: ${DTB_SIZE_MB}MB ($DTB_SIZE bytes)"
    echo ""
    
    # 检查 kernel 文件头
    echo "=== 验证 kernel 文件格式 ==="
    MAGIC=$(hexdump -n 4 -e '4/1 "%02x"' "$KERNEL_FILE")
    
    if [ "$MAGIC" = "4d5a0091" ] || [ "$MAGIC" = "4d5a4000" ]; then
        echo -e "${GREEN}✓ kernel 是有效的 ARM64 Image${NC}"
    else
        echo -e "${YELLOW}⚠ kernel 文件头: $MAGIC (可能是压缩格式)${NC}"
    fi
    
    # 检查 kernel-dtb 文件头
    echo ""
    echo "=== 验证 kernel-dtb 文件格式 ==="
    DTB_MAGIC=$(hexdump -n 4 -e '4/1 "%02x"' "$KERNEL_DTB_FILE")
    
    if [ "$DTB_MAGIC" = "d00dfeed" ]; then
        echo -e "${GREEN}✓ kernel-dtb 是有效的 DTB 文件${NC}"
    else
        echo -e "${YELLOW}⚠ kernel-dtb 文件头: $DTB_MAGIC${NC}"
    fi
    
    # 验证是否是拼接文件
    echo ""
    echo "=== 验证拼接关系 ==="
    
    # 在 kernel 中搜索 DTB magic (d00dfeed)
    DTB_OFFSET=$(grep -boa $'\xd0\x0d\xfe\xed' "$KERNEL_FILE" 2>/dev/null | head -1 | cut -d: -f1 || echo "")
    
    if [ -n "$DTB_OFFSET" ]; then
        echo -e "${GREEN}✓ 在 kernel 中找到 DTB 标记，偏移: $DTB_OFFSET${NC}"
        
        # 计算 Image 部分大小
        IMAGE_PART_SIZE=$DTB_OFFSET
        DTB_PART_SIZE=$((KERNEL_SIZE - DTB_OFFSET))
        
        echo ""
        echo "=== 拼接结构分析 ==="
        echo "Image 部分: $((IMAGE_PART_SIZE / 1024 / 1024))MB ($IMAGE_PART_SIZE bytes)"
        echo "DTB 部分:   $((DTB_PART_SIZE / 1024 / 1024))MB ($DTB_PART_SIZE bytes)"
        
        # 比较 DTB 部分大小
        if [ $DTB_PART_SIZE -eq $DTB_SIZE ]; then
            echo -e "${GREEN}✓ DTB 部分大小与 kernel-dtb 文件完全匹配！${NC}"
        else
            DIFF=$((DTB_PART_SIZE - DTB_SIZE))
            echo -e "${YELLOW}⚠ DTB 部分大小差异: $DIFF bytes${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}结论: 原厂 kernel = Image + kernel-dtb 拼接${NC}"
        echo "你需要: cat <自编译Image> <原厂kernel-dtb> > kernel"
    else
        echo -e "${YELLOW}⚠ 未在 kernel 中找到 DTB 标记${NC}"
        echo "可能是其他格式"
    fi
}

# 拼接功能
merge_kernel() {
    IMAGE_FILE=$1
    KERNEL_DTB_FILE=$2
    OUTPUT_FILE=${3:-"kernel_new"}
    
    if [ ! -f "$IMAGE_FILE" ]; then
        echo -e "${RED}错误: 找不到 $IMAGE_FILE${NC}"
        exit 1
    fi
    
    if [ ! -f "$KERNEL_DTB_FILE" ]; then
        echo -e "${RED}错误: 找不到 $KERNEL_DTB_FILE${NC}"
        exit 1
    fi
    
    echo "=== 输入文件 ==="
    IMAGE_SIZE=$(stat -f%z "$IMAGE_FILE" 2>/dev/null || stat -c%s "$IMAGE_FILE")
    DTB_SIZE=$(stat -f%z "$KERNEL_DTB_FILE" 2>/dev/null || stat -c%s "$KERNEL_DTB_FILE")
    
    echo "Image:      $((IMAGE_SIZE / 1024 / 1024))MB ($IMAGE_SIZE bytes)"
    echo "kernel-dtb: $((DTB_SIZE / 1024 / 1024))MB ($DTB_SIZE bytes)"
    echo ""
    
    # 验证 Image 格式
    MAGIC=$(hexdump -n 4 -e '4/1 "%02x"' "$IMAGE_FILE")
    if [ "$MAGIC" != "4d5a0091" ] && [ "$MAGIC" != "4d5a4000" ]; then
        echo -e "${YELLOW}⚠ 警告: Image 文件头不是标准 ARM64 格式 ($MAGIC)${NC}"
        read -p "是否继续? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # 拼接
    echo "=== 拼接中 ==="
    cat "$IMAGE_FILE" "$KERNEL_DTB_FILE" > "$OUTPUT_FILE"
    
    OUTPUT_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE")
    EXPECTED_SIZE=$((IMAGE_SIZE + DTB_SIZE))
    
    echo ""
    echo "=== 输出文件 ==="
    echo "文件名: $OUTPUT_FILE"
    echo "大小:   $((OUTPUT_SIZE / 1024 / 1024))MB ($OUTPUT_SIZE bytes)"
    
    if [ $OUTPUT_SIZE -eq $EXPECTED_SIZE ]; then
        echo -e "${GREEN}✓ 拼接成功！大小正确${NC}"
    else
        echo -e "${RED}✗ 大小不匹配！预期 $EXPECTED_SIZE，实际 $OUTPUT_SIZE${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}完成！用 $OUTPUT_FILE 替换原厂 boot.img 中的 kernel 文件${NC}"
}

# 执行
case $ACTION in
    verify)
        if [ "$#" -lt 3 ]; then
            echo "用法: $0 verify <原厂kernel> <原厂kernel-dtb>"
            exit 1
        fi
        verify_kernel "$2" "$3"
        ;;
    merge)
        if [ "$#" -lt 3 ]; then
            echo "用法: $0 merge <自编译Image> <原厂kernel-dtb> [输出文件名]"
            exit 1
        fi
        merge_kernel "$2" "$3" "$4"
        ;;
    check-version)
        if [ "$#" -lt 3 ]; then
            echo "用法: $0 check-version <自编译Image> <原厂kernel>"
            exit 1
        fi
        check_version "$2" "$3"
        ;;
    *)
        echo "未知操作: $ACTION"
        echo "可用操作: verify, merge, check-version"
        exit 1
        ;;
esac
