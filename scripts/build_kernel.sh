#!/bin/bash

# Android Kernel Build Script
# 用于在本地构建Android内核

set -e

echo "Android Kernel Build Script"
echo "=========================="

# 默认参数
DEVICE="mondrian"
TOOLCHAIN="clang"
CLEAN_BUILD=false
ENABLE_DOCKER=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -d|--device)
      DEVICE="$2"
      shift 2
      ;;
    -t|--toolchain)
      TOOLCHAIN="$2"
      shift 2
      ;;
    -c|--clean)
      CLEAN_BUILD=true
      shift
      ;;
    -D|--docker)
      ENABLE_DOCKER=true
      shift
      ;;
    -h|--help)
      echo "用法: $0 [选项]"
      echo "选项:"
      echo "  -d, --device    指定目标设备 (mondrian, vermeer, sheng)"
      echo "  -t, --toolchain 指定工具链 (clang, gcc)"
      echo "  -c, --clean     执行清洁构建"
      echo "  -D, --docker    在Docker容器中构建"
      echo "  -h, --help      显示帮助信息"
      exit 0
      ;;
    *)
      echo "未知选项: $1"
      echo "使用 -h 或 --help 查看帮助信息"
      exit 1
      ;;
  esac
done

# 验证设备参数
if [[ "$DEVICE" != "mondrian" && "$DEVICE" != "vermeer" && "$DEVICE" != "sheng" ]]; then
  echo "错误: 不支持的设备: $DEVICE"
  echo "支持的设备: mondrian, vermeer, sheng"
  exit 1
fi

# 验证工具链参数
if [[ "$TOOLCHAIN" != "clang" && "$TOOLCHAIN" != "gcc" ]]; then
  echo "错误: 不支持的工具链: $TOOLCHAIN"
  echo "支持的工具链: clang, gcc"
  exit 1
fi

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "项目根目录: $PROJECT_ROOT"
echo "目标设备: $DEVICE"
echo "工具链: $TOOLCHAIN"
echo "清洁构建: $CLEAN_BUILD"
echo "Docker支持: $ENABLE_DOCKER"

# 创建必要的目录
mkdir -p arch/arm64/configs out build_artifacts

# 如果是清洁构建，删除之前的构建产物
if [ "$CLEAN_BUILD" = true ]; then
  echo "执行清洁构建..."
  rm -rf out/*
fi

# 创建设备配置文件
CONFIG_FILE="arch/arm64/configs/${DEVICE}_defconfig"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "创建设备配置文件: $CONFIG_FILE"
  echo "# Default configuration for $DEVICE" > "$CONFIG_FILE"
  echo "CONFIG_ARM64=y" >> "$CONFIG_FILE"
  echo "CONFIG_ARCH_QCOM=y" >> "$CONFIG_FILE"
  echo "CONFIG_SMP=y" >> "$CONFIG_FILE"
  echo "CONFIG_HOTPLUG_CPU=y" >> "$CONFIG_FILE"
  echo "CONFIG_DEVTMPFS=y" >> "$CONFIG_FILE"
  echo "CONFIG_DEVTMPFS_MOUNT=y" >> "$CONFIG_FILE"
  echo "CONFIG_BLK_DEV_INITRD=y" >> "$CONFIG_FILE"
  echo "CONFIG_CMA=y" >> "$CONFIG_FILE"
  echo "CONFIG_PM_DEVFREQ=y" >> "$CONFIG_FILE"
  echo "CONFIG_CPU_FREQ=y" >> "$CONFIG_FILE"
  echo "CONFIG_CPUFREQ_DT=y" >> "$CONFIG_FILE"
  echo "CONFIG_ACPI=y" >> "$CONFIG_FILE"
  echo "CONFIG_CPU_IDLE=y" >> "$CONFIG_FILE"
  echo "CONFIG_NET=y" >> "$CONFIG_FILE"
  echo "CONFIG_INET=y" >> "$CONFIG_FILE"
  echo "CONFIG_IP_MULTICAST=y" >> "$CONFIG_FILE"
  
  # 设备特定配置
  case $DEVICE in
    mondrian)
      echo "CONFIG_MACH_XIAOMI_MONDRIAN=y" >> "$CONFIG_FILE"
      echo "CONFIG_QCOM_SM8475=y" >> "$CONFIG_FILE"
      ;;
    vermeer)
      echo "CONFIG_MACH_XIAOMI_VERMEER=y" >> "$CONFIG_FILE"
      echo "CONFIG_QCOM_SM8550=y" >> "$CONFIG_FILE"
      ;;
    sheng)
      echo "CONFIG_MACH_XIAOMI_SHENG=y" >> "$CONFIG_FILE"
      echo "CONFIG_QCOM_SM8550=y" >> "$CONFIG_FILE"
      echo "CONFIG_INPUT_TOUCHSCREEN=y" >> "$CONFIG_FILE"
      ;;
  esac
fi

# 设置构建环境变量
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-

# 根据选择的工具链设置CC和CXX
if [ "$TOOLCHAIN" = "clang" ]; then
  echo "使用Clang工具链"
  export CC=clang
  export CXX=clang++
else
  echo "使用GCC工具链"
  export CC=aarch64-linux-gnu-gcc
  export CXX=aarch64-linux-gnu-g++
fi

# Docker支持（如果启用）
if [ "$ENABLE_DOCKER" = true ]; then
  echo "Docker支持暂未实现，使用本地构建模式"
  # 这里可以添加Docker构建逻辑
  # 例如: docker run --rm -v $PWD:$PWD -w $PWD android-build-image ./scripts/build_kernel.sh -d $DEVICE -t $TOOLCHAIN $([ "$CLEAN_BUILD" = true ] && echo "-c")
fi

# 加载配置
echo "加载配置文件: ${DEVICE}_defconfig"
make O=out ${DEVICE}_defconfig

# 开始构建
echo "开始构建内核..."
make -j$(nproc) O=out \
  CC=${CC} \
  CXX=${CXX}

echo "构建完成！"

# 收集构建产物
echo "收集构建产物..."
mkdir -p build_artifacts/${DEVICE}

# 复制内核镜像和模块
if [ -f out/arch/arm64/boot/Image.gz ]; then
  cp out/arch/arm64/boot/Image.gz build_artifacts/${DEVICE}/
  echo "复制内核镜像: Image.gz"
fi

if [ -f out/arch/arm64/boot/Image.gz-dtb ]; then
  cp out/arch/arm64/boot/Image.gz-dtb build_artifacts/${DEVICE}/
  echo "复制带设备树的内核镜像: Image.gz-dtb"
fi

# 复制设备树文件
if [ -d out/arch/arm64/boot/dts ]; then
  cp -r out/arch/arm64/boot/dts build_artifacts/${DEVICE}/
  echo "复制设备树文件"
fi

# 检查是否有模块需要复制
if [ -d out/lib/modules ]; then
  cp -r out/lib/modules build_artifacts/${DEVICE}/
  echo "复制内核模块"
fi

echo "构建产物已保存到: build_artifacts/${DEVICE}/"
echo "构建成功完成！"