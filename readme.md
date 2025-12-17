# Redmi Note 14 5G Kernel Action

本项目是一个基于 GitHub Actions 的自动化内核构建脚本。目前已使用 `build-gki-zyc-clang18.yml` 工作流成功为 **Redmi Note 14 5G** 构建了支持高级特性的内核。

小米内核源码仓库：
https://github.com/MiCode/Xiaomi_Kernel_OpenSource

## ✨ 特性 (Features)

* **自动构建**: 基于 GitHub Actions，无需本地环境，在线云端编译。
* **KernelSU 支持**: 内置 KernelSU (默认为 main 分支)，提供强大的 root 权限管理。
* **LXC & Docker 支持**: 集成 `add-lxc-docker-custom.sh` 脚本，自动开启 cgroup、namespace、overlayfs 等 Docker 运行所需的内核配置。
* **GKI 修复**: 针对 GKI 内核编译过程中的常见报错（如栈帧大小限制、函数原型检查等）进行了自动化修复。
* **AnyKernel3 打包**: 自动打包为刷机包，支持 TWRP/KernelSU App 直接刷入。

## 🚀 已验证构建 (Verified Build)

* **设备**: Redmi Note 14 5G
* **工作流**: `GKI 内核 zyc clang18` (`build-gki-zyc-clang18.yml`)
* **内核源码**: Xiaomi Kernel OpenSource (Branch: `beryl-u-oss`)
* **编译器版本**: Clang 18.0.0

## 🛠️ 如何使用 (Usage)

1. **Fork 本仓库** 到你的 GitHub 账号。
2. **修改配置文件**:
编辑项目根目录下的 `config.env` 文件，根据你的需求调整参数（如下方说明）。
3. **运行工作流**:
* 进入仓库的 "Actions" 页面。
* 在左侧选择 **"GKI 内核 zyc clang18"** (对应文件名 `build-gki-zyc-clang18.yml`)。
* 点击 "Run workflow" 按钮开始构建。


4. **下载产物**:
构建完成后，在 Action 运行详情页面的 "Artifacts" 区域下载生成的内核刷机包 (`beryl_lxc-docker-kernel_*.zip`)。

## ⚙️ 配置文件说明 (Config Guide)

主要通过 `config.env` 控制构建行为：

| 变量名 | 默认值/示例 | 说明 |
| --- | --- | --- |
| `KERNEL_SOURCE` | `https://github.com/MiCode/Xiaomi_Kernel_OpenSource/` | 内核源码仓库地址 |
| `KERNEL_SOURCE_BRANCH` | `beryl-u-oss` | 源码分支名称 (请确认为你的设备分支) |
| `KERNEL_CONFIG` | `gki_defconfig` | 编译使用的 defconfig 文件名 |
| `KERNEL_ZIP_NAME` | `beryl_lxc-docker-kernel...` | 生成的刷机包名称 |
| `LLVM_CONFIG` | `y` | 是否开启 LLVM=1 和 LLVM_IAS=1 编译参数 |
| `ENABLE_KERNELSU` | `true` | 是否集成 KernelSU |
| `KERNELSU_TAG` | `main` | KernelSU 的分支或版本 Tag |
| `ENABLE_LXC_DOCKER` | `true` | 是否开启 Docker/LXC 相关支持 |
| `ENABLE_KVM` | `false` | 是否开启 KVM 虚拟化支持 (默认关闭) |
| `KERNEL_IMAGE_NAME` | `Image` | 编译出的内核镜像文件名 (GKI通常为 Image) |

## ⚠️ 注意事项

* **GKI 兼容性**: 本构建脚本包含针对 GKI 内核的特定补丁（如移除 runc 补丁步骤，因为 GKI 通常不需要或不兼容旧版补丁，且增加了栈大小警告的修复）。
* **Docker 脚本**: `add-lxc-docker-custom.sh` 会自动向 defconfig 添加大量网络和命名空间相关的配置，确保 Docker 能正常运行。
* **刷入风险**: 刷入第三方内核有风险，请务必在刷入前备份你的 `boot` 和 `dtbo` 分区。
