# Android Kernel Build System

这是一个用于构建Android内核的自动化构建系统，支持多个设备（mondrian、vermeer、sheng），可通过GitHub Actions或本地环境进行构建。

## 功能特性

- 支持通过GitHub Actions自动构建内核
- 支持在本地环境手动运行构建脚本
- 支持多种构建选项（不同设备、工具链选择、清洁构建）
- 自动收集和上传构建产物
- 支持基于事件的自动触发（push到main/master分支或创建标签）

## 使用方法

### 1. 通过GitHub Actions手动触发

1. 进入你的GitHub仓库页面
2. 点击"Actions"选项卡
3. 选择"Build Android Kernels"工作流
4. 点击"Run workflow"按钮
5. 选择目标设备和其他选项
6. 点击"Run workflow"开始构建

### 2. 自动触发

当满足以下条件时，构建将自动触发：
- 推送到`main`或`master`分支
- 创建以`v`开头的标签（如`v1.0`）

### 3. 本地环境手动运行

在本地环境中，你可以直接运行构建脚本来构建内核。以下是详细步骤：

### 3.1 环境准备

在运行构建脚本之前，请确保你的系统已安装以下依赖：

- **Ubuntu/Debian系统**：
  ```bash
  sudo apt-get update
  sudo apt-get install -y build-essential libncurses5-dev bison flex libssl-dev bc ccache
  ```

- **工具链**：
  - 确保`toolchains`目录中包含了所需的工具链
  - 或配置环境变量指向系统已安装的工具链

### 3.2 运行构建脚本

构建脚本位于`scripts/build_kernel.sh`，使用以下命令运行：

```bash
# 基本用法（指定设备）
./scripts/build_kernel.sh --device mondrian

# 指定设备和工具链
./scripts/build_kernel.sh --device mondrian --toolchain clang

# 进行清洁构建
./scripts/build_kernel.sh --device mondrian --clean

# 完整参数示例
./scripts/build_kernel.sh --device mondrian --toolchain gcc --clean
```

### 3.3 脚本参数说明

构建脚本支持以下参数：

- `-d, --device <device>`：**必需**，指定目标设备（mondrian、vermeer或sheng）
- `-t, --toolchain <toolchain>`：指定工具链（clang或gcc），默认使用clang
- `-c, --clean`：启用清洁构建模式，删除之前的构建产物
- `-h, --help`：显示帮助信息

## 构建选项

- **目标设备**：选择要构建的设备（mondrian、vermeer、sheng）
- **工具链选择**：选择使用clang或gcc工具链
- **清洁构建**：选择是否进行清洁构建（删除之前的构建产物）
- **启用Docker**：选择是否在Docker容器中构建（目前已配置但未完全实现）

## 项目结构

```
├── .github/workflows/  # GitHub Actions工作流配置
├── arch/arm64/configs/ # 设备配置文件
├── build_artifacts/    # 构建产物目录
├── out/               # 构建输出目录
├── qcom-dependencies/ # 高通相关依赖
├── scripts/           # 构建脚本（可扩展）
└── toolchains/        # 工具链目录
```

## 注意事项

1. 首次构建时，系统会自动创建基础配置文件
2. 构建完成后，可以在Actions页面下载构建产物（GitHub Actions方式）或在`build_artifacts`目录中找到（本地构建方式）
3. 构建产物包括内核镜像、设备树文件和内核模块
4. 使用ccache加速构建过程，缓存大小为5GB
5. 确保脚本具有执行权限，可以使用`chmod +x ./scripts/build_kernel.sh`添加执行权限

## 故障排除

如果构建失败，可以检查以下几点：

1. 确保所有依赖都已正确安装
2. 检查配置文件是否正确
3. 查看GitHub Actions日志以获取详细错误信息（GitHub Actions方式）
4. 在本地构建时，检查终端输出的错误信息
5. 确保目标设备名称拼写正确（mondrian、vermeer或sheng）
6. 验证工具链路径是否正确

## 自定义扩展

如果你需要添加新设备或自定义构建过程，可以：

1. 在`.github/workflows/build-kernel.yml`中添加新设备到选项列表
2. 修改配置文件生成脚本以支持新设备
3. 根据需要添加或修改构建步骤