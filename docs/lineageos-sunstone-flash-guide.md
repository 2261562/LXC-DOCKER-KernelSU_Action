# Redmi Note 12 5G (sunstone) 刷入 LineageOS 指南

## 设备信息

- **设备**: Redmi Note 12 5G
- **代号**: sunstone
- **SoC**: Qualcomm SM6375 (骁龙 695)
- **目标 ROM**: Stone LineageOS 22.2 (Android 15)

---

## ROM 下载地址

### Stone LineageOS 22.2

- **XDA 帖子**: https://xdaforums.com/t/closed-rom-15-stone-lineageos-22-2-unofficial.4699278/
- **ROM 下载**: https://sourceforge.net/projects/baunilla/files/stone/lineage-22.2-20250518-UNOFFICIAL-stone.zip/download
- **Recovery (boot.img)**: https://sourceforge.net/projects/baunilla/files/stone/boot.img/download

> ⚠️ 注意: 该 ROM 状态为 **Discontinued (已停止维护)**，最后更新 2025-05-18

---

## ROM 信息

| 项目 | 信息 |
|------|------|
| Android 版本 | Android 15 |
| 内核版本 | Linux 5.4.x |
| SELinux | Enforcing |
| 开发者 | baunilla |
| 适用设备 | Redmi Note 12 5G / Poco X5 5G (stone/sunstone) |

---

## 内核源码仓库

### 开发者 GitHub

- **开发者主页**: https://github.com/baunilla

| 仓库 | 地址 | 说明 |
|------|------|------|
| 内核源码 | https://github.com/baunilla/android_device_xiaomi_stone-kernel | ⭐ 编译内核用这个 |
| 设备树 | https://github.com/baunilla/android_device_xiaomi_stone | Device Tree |

> 注意: 内核仓库名是 `android_device_xiaomi_stone-kernel`，不是常见的 `android_kernel_*` 命名格式

**编译内核时需要确认:**
1. 查看仓库的分支 (可能是 `lineage-22` 或 `main`)
2. 查看仓库中的 defconfig 文件位置
3. 确认内核版本 (应该是 5.4.x)

---

## 刷机前备份 (重要!)

### 方法一: 使用 TWRP 完整备份

1. **下载 TWRP**
   - 搜索 `TWRP sunstone` 或使用 OrangeFox Recovery
   - 下载地址: https://twrp.me/xiaomi/xiaomiredminote125g.html

2. **进入 Recovery**
   ```
   关机 → 同时按住 电源键 + 音量上键
   ```

3. **备份分区**
   - 进入 TWRP → Backup
   - 选择以下分区:
     - ✅ Boot
     - ✅ System
     - ✅ Vendor
     - ✅ Data (可选，会很大)
     - ✅ EFS (重要! 包含 IMEI)
     - ✅ Persist
     - ✅ Modem
   - 滑动确认备份
   - 备份文件保存在 `/sdcard/TWRP/BACKUPS/`

4. **将备份复制到电脑**
   ```bash
   adb pull /sdcard/TWRP/BACKUPS/ ./phone_backup/
   ```

### 方法二: 使用 ADB 备份关键分区

1. **解锁 Bootloader** (如果还没解锁)
   ```bash
   # 进入 fastboot 模式
   adb reboot bootloader
   
   # 检查解锁状态
   fastboot oem device-info
   
   # 解锁 (会清除数据!)
   fastboot oem unlock
   ```

2. **备份关键分区镜像**
   ```bash
   # 进入 fastboot 模式
   adb reboot bootloader
   
   # 备份 boot 分区
   fastboot getvar partition-size:boot_a
   fastboot getvar partition-size:boot_b
   
   # 使用 dd 备份 (需要 root 或 recovery)
   adb shell su -c "dd if=/dev/block/bootdevice/by-name/boot_a of=/sdcard/boot_a.img"
   adb shell su -c "dd if=/dev/block/bootdevice/by-name/boot_b of=/sdcard/boot_b.img"
   adb shell su -c "dd if=/dev/block/bootdevice/by-name/efs of=/sdcard/efs.img"
   adb shell su -c "dd if=/dev/block/bootdevice/by-name/persist of=/sdcard/persist.img"
   adb shell su -c "dd if=/dev/block/bootdevice/by-name/modem_a of=/sdcard/modem_a.img"
   
   # 拉取到电脑
   adb pull /sdcard/boot_a.img
   adb pull /sdcard/boot_b.img
   adb pull /sdcard/efs.img
   adb pull /sdcard/persist.img
   adb pull /sdcard/modem_a.img
   ```

### 方法三: 下载官方 Fastboot ROM (救砖必备)

1. **下载小米官方 Fastboot ROM**
   - 官方地址: https://xiaomifirmwareupdater.com/miui/sunstone/
   - 或: https://mifirm.net/model/sunstone.thtml
   - 选择你当前的 MIUI 版本

2. **保存 MiFlash 工具**
   - 下载: https://xiaomiflashtool.com/
   - 这是救砖的最后手段

---

## 刷机步骤

### 前置条件

- [x] Bootloader 已解锁
- [x] 已备份所有重要数据
- [x] 已下载官方 Fastboot ROM (救砖用)
- [x] 电池电量 > 50%

### 刷入 LineageOS

1. **下载所需文件**
   - LineageOS ROM zip
   - LineageOS Recovery img
   - (可选) GApps: https://wiki.lineageos.org/gapps

2. **刷入 Recovery**
   ```bash
   adb reboot bootloader
   fastboot flash recovery lineage-recovery.img
   fastboot reboot recovery
   ```

3. **进入 Recovery 执行格式化**
   - Factory Reset → Format data/factory reset
   - 输入 `yes` 确认

4. **刷入 ROM**
   - Apply Update → Apply from ADB
   ```bash
   adb sideload lineage-22.2-xxxxx-sunstone.zip
   ```

5. **(可选) 刷入 GApps**
   ```bash
   adb sideload MindTheGapps-xxxxx.zip
   ```

6. **重启**
   - Reboot → System

---

## 救砖方法

### 情况一: 能进 Fastboot

```bash
# 使用 MiFlash 刷入官方 ROM
# 或手动刷入:
fastboot flash boot boot.img
fastboot flash system system.img
fastboot flash vendor vendor.img
fastboot reboot
```

### 情况二: 能进 Recovery

- 使用之前的 TWRP 备份恢复
- 或 sideload 官方 ROM

### 情况三: 完全变砖 (EDL 模式)

1. 关机状态下，同时按住 **音量上 + 音量下**，插入 USB
2. 设备进入 EDL (9008) 模式
3. 使用 MiFlash 选择 Fastboot ROM，刷入

> ⚠️ EDL 模式可能需要授权账号，建议提前在小米社区申请

---

## 刷入自编译内核

刷入 LineageOS 后，可以使用本仓库的 workflow 编译支持 Docker 的内核:

1. Fork 本仓库
2. 修改 workflow 中的内核源码地址为 LineageOS 内核
3. 运行 GitHub Actions 编译
4. 下载 AnyKernel3 zip
5. 在 Recovery 中刷入

---

## 参考链接

- [XDA Redmi Note 12 5G 论坛](https://xdaforums.com/f/redmi-note-12-5g.12805/)
- [LineageOS Wiki](https://wiki.lineageos.org/)
- [小米解锁工具](https://www.miui.com/unlock/)
- [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools)
