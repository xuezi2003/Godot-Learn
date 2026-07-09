# C2-P9a：2D 雾效

> 使用噪声纹理、Parallax2D 与 VisualShader 制作动态滚动的 2D 雾气层，并复制到不同关卡中调整氛围。

## 1. 场景树整理

- 将大量视差层、瓦片层、道具节点分组，便于管理：

```
Level
├── BackgroundParallax
│   ├── Sky
│   ├── FarTrees
│   ├── MidTrees
│   └── MistLayers
├── LevelTilemaps
├── Props
├── Player
└── ForegroundParallax
```

## 2. 雾层基础结构

1. 在 `BackgroundParallax` 下新建 **Parallax2D**，命名为 `MistParallax`。
2. 子节点添加 **Sprite2D**，命名为 `MistSprite`。
3. 为 Sprite2D 创建纹理：**NoiseTexture2D**。

### 噪声纹理设置

| 属性 | 建议值 | 说明 |
|------|--------|------|
| Seamless | 开启 | 纹理可无缝平铺 |
| Normalize | 关闭 | 更均匀柔和；开启则对比度更高 |
| Frequency | 0.5 左右 | 控制噪点大小 |
| Color Ramp | 白→透明 | 用渐变替换默认黑白 |

- 可让雾色带一点淡蓝/淡绿，与场景色调保持一致。

## 3. 视差与重复

- 设置 `Scroll Scale` 约为 **1.2 ~ 1.3**，使雾气位于近景与前景之间。
- 设置 `Repeat Size` 为纹理尺寸（如 512×512）。
- 设置 `Repeat Count` 为 2 或更大，确保覆盖关卡宽度。
- 开启 `Auto Scroll` 的 X 轴（如 `-25`），让雾气水平漂移。

## 4. 用 VisualShader 实现顶部淡出

### 创建材质

1. 在 `materials_and_shaders/` 下新建 **ShaderMaterial** 并保存。
2. 点击 **Shader** 旁的下拉 → 新建 **VisualShader**。
3. 模式选择 **CanvasItem**。
4. 确保在着色器编辑器顶部切换到 **Fragment** 模式。

### 节点连接

1. 添加 **Texture2D** 节点，加载一张 **GradientTexture2D**（垂直方向，底部白色、顶部透明）。
2. 添加 **Input → Alpha** 节点，获取原噪声纹理的 Alpha。
3. 添加 **Scalar → Multiply** 节点，将原 Alpha 与渐变 Alpha 相乘。
4. 将乘法结果连接到 **Output → Alpha**。
5. 这样雾气底部浓密、顶部逐渐透明。

### 调整

- 将 Sprite2D 高度设为 128 左右，放置在地表附近。
- 通过 Sprite2D 的 **Modulate** 调整颜色与透明度。
- 可开启/关闭 `Normalize` 观察不同效果。

## 5. 多层雾效

- 复制雾层节点组，得到第二层雾。
- 将副本设为 **Make Unique**，避免同时修改原纹理。
- 调整第二层的：
  - 噪声 `Seed` / `Frequency`
  - 滚动速度（如 `-15` 与 `-25`）
  - 颜色调制
  - 滚动比例
- 两层朝相反或不同速度移动，可产生更动态的雾气效果。

## 6. 应用到其他关卡

- 将雾层节点组复制到第二关、第三关。
- 根据关卡氛围调整颜色：森林偏绿/青，地牢偏暗/橙。
- 适当降低透明度，避免遮挡玩法或过于浓重。

## 7. 课后任务

- 为每个主要关卡添加 1~2 层动态雾气。
- 尝试用 VisualShader 改变雾气颜色或边缘形状。
- 调整 Auto Scroll 与 Scroll Scale，找到适合当前关卡的节奏。
