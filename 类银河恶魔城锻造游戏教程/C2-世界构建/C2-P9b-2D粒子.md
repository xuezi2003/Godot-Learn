# C2-P9b：2D 粒子

> 使用 GPUParticles2D 为火把添加火花，并在关卡中布置漂浮光点/尘埃粒子，增强场景生气。

## 1. 火炬火花

### 节点结构

- 打开 `props/torch.tscn`。
- 在 AnimatedSprite2D 同级添加 **GPUParticles2D**。
- 新建 **ParticleProcessMaterial**。

### 关键参数

| 分组 | 参数 | 建议值 | 说明 |
|------|------|--------|------|
| 基础 | Amount | 3 ~ 8 | 火花数量，避免过多 |
| 基础 | Lifetime Randomness | 1.0 | 每个粒子寿命随机 |
| 生成 | Emission Shape | Point | 从火炬顶部单点发射 |
| 生成 | Initial Velocity (min/max) | 20 / 300 | 有的轻柔飘出，有的快速飞溅 |
| 生成 | Direction | (0, -16) | 向上发射 |
| 动画 | Angular Velocity (min/max) | -200 / 200 | 火花旋转飞溅 |
| 动画 | Turbulence → Influence (min/max) | 0.1 / 0.3 | 让轨迹不规则、更像真实火花 |
| 显示 | Color Ramp | 黄 → 橙 → 透明 | 模拟高温到冷却 |
| 显示 | Light Mode（材质） | Add / Unshaded | 不受场景光照影响，自发光 |

### 效果要点

- 湍流（Turbulence）是火花效果的核心，能让粒子产生随机蜿蜒轨迹。
- 数量设为 3 左右即可获得不刺眼的火星效果。
- 若想让火花更亮，可在颜色渐变中使用 HDR 强度（Intensity > 1）。

## 2. 漂浮光点/尘埃

### 用途

- 在森林等场景中添加缓慢漂浮的发光微粒，营造空气感与神秘感。

### 节点与纹理

- 添加 **GPUParticles2D**。
- 纹理使用 **GradientTexture2D**：
  - Fill 设为 **Radial**（径向）。
  - 勾选 **Mirror**（镜像）。
  - 尺寸 16×16。
  - 颜色：偏绿/青，中心高亮，边缘透明。

### 材质

- 新建 **CanvasItemMaterial**。
- Light Mode 设为 **Add** 或 **Unshaded**。

### 关键参数

| 分组 | 参数 | 建议值 | 说明 |
|------|------|--------|------|
| 基础 | Amount | 50 左右 | 大量微粒 |
| 基础 | Lifetime | 5 s | 随机寿命 |
| 生成 | Emission Shape | Box | 覆盖整个区域 |
| 生成 | Box Extents | 600 / 200 | 按关卡大小调整 |
| 生成 | Initial Velocity (min/max) | 0 / 300 | 随机慢速漂浮 |
| 动画 | Gravity | 10 | 几乎不受重力 |
| 动画 | Turbulence Influence | 较低 | 轻微随机漂浮 |
| 显示 | Scale (min/max) | 0.75 / 1.25 | 大小不一 |
| 显示 | Hue Variation | 0.05 | 颜色轻微变化 |
| 显示 | Color Ramp | 透明 → 颜色 → 透明 | 淡入淡出 |

### 可见性矩形

- 粒子只在 **Visibility Rect** 范围内渲染。
- 若矩形过小，粒子会在摄像机靠近/远离时突然消失。
- 将矩形设为足够覆盖关卡，或将其中心偏移到关卡中心。

## 3. 性能提示

- GPUParticles2D 在现代设备上性能优于 CPUParticles2D。
- 若目标平台不支持 GPU 粒子，可改用 CPUParticles2D。
- 大量粒子会占用 GPU，数量与 Lifetime 需要权衡。

## 4. 课后任务

- 为所有火把添加火花粒子。
- 在第一关添加漂浮光点/尘埃层。
- 调整数量、颜色与湍流，使粒子效果既生动又不干扰 gameplay。
