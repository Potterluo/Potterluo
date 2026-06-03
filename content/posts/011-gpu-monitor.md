---
title: "GPU 监控工具对比：从 nvidia-smi 到 nvtop，谁最好用？"
date: 2026-06-03T16:00:00+08:00
draft: false
description: "对比 btop、nvidia-smi、gpustat、nvtop 等 GPU/CPU 监控工具，附安装和使用方法"
tags:
  - GPU
  - 运维
  - 工具
  - LLM
categories:
  - 技术分享
authors:
  - Potterluo
---

作为 LLM 工程师，GPU 是我们最亲密的工作伙伴。训练模型时需要关注显存占用，推理服务需要监控 GPU 利用率，长时间运行的任务还需要留意温度防止过热。面对这些需求，选择合适的监控工具能极大提升工作效率。本文将对比几种主流的 GPU/CPU 监控工具，帮助你找到最适合自己场景的选择。

---

## 老牌经典：nvidia-smi

nvidia-smi 是 NVIDIA 官方提供的 GPU 管理工具，几乎所有 NVIDIA GPU 环境都自带。它是最基础的 GPU 监控方案，功能稳定但界面相对简陋。

### 安装方式

通常无需单独安装，NVIDIA 驱动会自动部署：

```bash
# 检查是否可用
nvidia-smi

# 如果提示找不到命令，说明驱动未正确安装
# Ubuntu 安装驱动示例
sudo apt install nvidia-driver-535
```

### 使用技巧

```bash
# 基础查询
nvidia-smi

# 持续监控（每 1 秒刷新）
nvidia-smi -l 1

# 查看详细信息
nvidia-smi -q

# 只看显存占用
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

### 适用场景

- **快速诊断**：排查 GPU 是否正常工作、驱动版本等
- **脚本集成**：CSV 格式输出便于自动化采集
- **服务器环境**：无需额外安装，轻量可靠

### 局限性

界面是纯文本表格，不支持进程级 GPU 占用详情，刷新体验不如图形化工具流畅。适合作为"第一道检查防线"，但不适合长时间实时监控。

---

## 简洁轻量：gpustat

gpustat 由 wookayin 开发，目标是提供一个比 nvidia-smi 更美观、更易读的 GPU 状态展示。它基于 Python 实现，安装简单，界面清爽。

### 安装方式

```bash
# 普通安装（需要 pip）
pip install gpustat

# 无 root 权限环境
pip install --user gpustat

# 从 GitHub 安装最新版
pip install git+https://github.com/wookayin/gpustat.git
```

### 使用方式

```bash
# 基础查看
gpustat

# 持续监控（类似 watch -n 1）
gpustat -cp

# 显示进程占用
gpustat -a

# 只监控特定 GPU
gpustat -i 0,1
```

### 输出示例

```
[0] NVIDIA RTX 4090 (UUID: GPU-xxx) | 45°C, 78% | 18022 / 24564 MB | (python/12345: 15GB)
[1] NVIDIA RTX 4090 (UUID: GPU-xxx) | 42°C, 12% | 2048 / 24564 MB |
```

一行输出就能看到温度、利用率、显存、进程占用，信息密度高且配色友好。

### 适用场景

- **个人开发环境**：pip 安装无需 root，适合受限环境
- **多 GPU 服务器**：一行展示所有 GPU 状态
- **终端用户**：喜欢简洁信息展示的工程师

### 局限性

功能相对单一，只展示 GPU 状态，不包含 CPU、内存等系统资源。适合作为 GPU 专项监控工具，不适合作为全面的系统监控方案。

---

## htop 体验：nvtop

nvtop（NVIDIA TOP）借鉴了 htop 的交互式界面设计，为 GPU 监控带来图形化体验。它支持多 GPU，能显示进程级 GPU 占用，界面直观易用。

### 安装方式

```bash
# Ubuntu/Debian
sudo apt install nvtop

# Arch Linux
sudo pacman -S nvtop

# Fedora
sudo dnf install nvtop

# 从源码编译（其他发行版）
git clone https://github.com/Syllo/nvtop.git
cd nvtop
mkdir build && cd build
cmake ..
make
sudo make install
```

### 功能特性

nvtop 界面分为多个区域：

- **GPU 概览区**：显示所有 GPU 的温度、利用率、显存、功耗
- **进程列表区**：类似 htop，显示每个进程的 GPU 占用
- **图表区**：实时绘制利用率曲线

交互操作支持鼠标点击、快捷键筛选、进程排序等。

### 使用技巧

```bash
# 启动 nvtop
nvtop

# 指定刷新间隔（毫秒）
nvtop -d 1000

# 禁用特定 GPU
nvtop --gpu-disable 2,3
```

快捷键：
- `F6`：选择排序字段
- `F9`：终止进程
- `F10`：退出

### 适用场景

- **长时间监控**：交互式界面，适合边工作边观察
- **多 GPU 环境**：一目了然看到所有 GPU 状态
- **进程排查**：快速定位占用 GPU 的进程

### 局限性

只支持 NVIDIA GPU（部分版本支持 AMD），不显示 CPU、内存等系统资源。适合专注 GPU 监控，不适合全面系统运维。

---

## 综合监控：btop + GPU 插件

btop（bashtop++）是现代化的系统监控工具，界面华丽，支持 CPU、内存、磁盘、网络、进程等全方位监控。通过第三方插件可以扩展 GPU 支持。

### 安装 btop

```bash
# Ubuntu/Debian
sudo apt install btop

# macOS
brew install btop

# 从源码安装
git clone https://github.com/aristocratos/btop.git
cd btop
make
sudo make install
```

### 添加 GPU 支持

官方 btop 不直接支持 GPU，需要使用第三方插件：

```bash
# btop-gpu 插件（支持 NVIDIA）
git clone https://github.com/romner-set/btop-gpu.git
cd btop-gpu
./install.sh
```

安装后启动 btop，GPU 信息会出现在独立面板中。

### 界面体验

btop 界面采用色块、图表、进度条等可视化元素：

- **CPU 栘状图**：多核利用率一目了然
- **内存环形图**：直观展示内存占用
- **磁盘网络速度条**：实时 IO 速率
- **进程列表**：支持鼠标交互、搜索筛选

GPU 插件会在右上角增加显存、利用率、温度显示。

### 适用场景

- **全面系统监控**：CPU、内存、磁盘、网络、GPU 一站式查看
- **开发工作站**：本地环境资源监控
- **教学演示**：界面美观，适合录制教程

### 局限性

GPU 支持依赖第三方插件，可能存在兼容性问题。官方版本更新频繁，插件跟进可能滞后。适合作为综合系统监控，GPU 监控精度不如专用工具。

---

## 工具对比总结

| 工具 | 安装难度 | 界面体验 | GPU 信息 | CPU/内存 | 进程详情 | 适用场景 |
|------|---------|---------|---------|---------|---------|---------|
| nvidia-smi | ⭐ 无需安装 | 纯文本 | ✅ 基础 | ❌ | ❌ | 快速诊断、脚本集成 |
| gpustat | ⭐ pip 安装 | 清爽简洁 | ✅ 详细 | ❌ | ✅ | 个人开发、多 GPU 服务器 |
| nvtop | ⭐⭐ 包管理/编译 | htop 风格 | ✅ 详细 | ❌ | ✅ | 交互监控、进程排查 |
| btop+GPU | ⭐⭐⭐ 多步安装 | 华丽图形 | ✅ 插件 | ✅ | ✅ | 综合系统监控 |

---

## 实战建议

### 场景 1：LLM 推理服务监控

推荐组合：**gpustat + btop**

- gpustat 专注 GPU 状态，一行输出便于日志采集
- btop 监控系统整体负载，防止 CPU/内存瓶颈

```bash
# 推理服务启动后，后台监控
gpustat -cp > gpu_log.txt &
btop &
```

### 场景 2：模型训练任务

推荐：**nvtop**

训练任务通常 GPU 利用率持续高位，nvtop 的交互界面便于随时观察进程状态，温度曲线能预警过热风险。

```bash
nvtop -d 500  # 500ms 刷新，更流畅
```

### 场景 3：服务器运维巡检

推荐：**nvidia-smi + gpustat**

- nvidia-smi 确认驱动状态、GPU 基础信息
- gpustat 快速查看所有 GPU 运行状态

```bash
# 日常巡检脚本
nvidia-smi -q | grep -A 3 "GPU 0000"
gpustat -cp
```

### 场景 4：受限环境（无 root）

推荐：**gpustat**

pip install --user 无需管理员权限，适合共享服务器、云环境容器等受限场景。

---

## 结语

GPU 监控工具各有特色，没有"最好的"，只有"最适合的"。nvidia-smi 是必备基础，gpustat 适合快速查看，nvtop 提供交互体验，btop 覆盖全面系统。建议根据实际场景组合使用，让 GPU 状态透明可控，助力 LLM 开发工作更高效。

最后提醒：监控只是手段，理解数据才是关键。GPU 利用率 100% 不一定代表高效，显存占用低可能是 batch size 太小，温度持续高位需要检查散热。结合业务场景解读监控数据，才能真正发挥工具价值。