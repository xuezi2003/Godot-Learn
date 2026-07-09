# C3-P5b：修复地图 BUG

> 本集修复了上一集中地图节点出口位置计算错误的问题，主要原因是未考虑关卡边界（LevelBounds）的偏移量，以及矩形高度对出口绘制的影响。

## 1. 问题描述

- 在较宽或异形关卡中，地图节点上绘制的出口/过渡块位置与实际关卡不符。
- 某些出口被镜像或错位，导致地图无法正确反映关卡连接关系。

## 2. 原因分析

1. **忽略了关卡边界偏移**：
   - 之前计算过渡位置时直接使用过渡区域的绝对位置，没有减去 `LevelBounds` 的偏移量。
   - 当 `LevelBounds` 不在 `(0, 0)` 时，所有出口都会偏移。

2. **未正确处理矩形高度**：
   - 顶部/底部出口的绘制高度为 3 像素，但之前计算偏移时只留了 2 像素边距，导致矩形超出或覆盖边框。

## 3. 修复方案

### 3.1 引入位置变量

- 在计算每个方向的入口偏移前，先计算过渡区域相对于 `LevelBounds` 的位置：

```gdscript
var pos := transition.position - level_bounds.position
pos /= SCALE_FACTOR
```

- 这样 `pos` 就是以地图节点坐标系为基准的偏移。

### 3.2 重新计算四个方向的偏移

```gdscript
# 上方出口：记录 X 偏移，Y 固定在顶部（考虑矩形高度）
if transition.is_top_exit():
    entrances_top.append(pos.x)
    # 绘制时 y = 0 - 3 或 0 - 2，视边框宽度而定

# 右侧出口：记录 Y 偏移，X 固定在右侧
if transition.is_right_exit():
    entrances_right.append(pos.y)

# 下方出口：记录 X 偏移，Y 固定在底部（减去矩形高度和边距）
if transition.is_bottom_exit():
    entrances_bottom.append(pos.x)

# 左侧出口：记录 Y 偏移，X 固定在左侧
if transition.is_left_exit():
    entrances_left.append(pos.y)
```

### 3.3 调整底部偏移

- 对于底部出口，为了让 3 像素高的矩形不超出房间底部，需要将 Y 偏移减去 5（2 像素边距 + 3 像素矩形高度）：

```gdscript
# 在创建过渡块时
bottom_block.position.y = size.y - 5
bottom_block.size.y = 3
```

- 顶部偏移保持 `-2` 或 `0`，因为矩形从顶部向下绘制。

### 3.4 清理冗余代码

- 之前为每个方向重复进行 `除以 SCALE_FACTOR` 的操作，现在统一在 `pos` 变量中完成。
- 减少了 `if/elif` 分支中的重复数学计算。

## 4. 验证步骤

1. 打开暂停菜单中的地图节点。
2. 选择每个 `MapNode` 并点击 Inspector 中的 **Update** 按钮。
3. 对比实际关卡场景的入口布局与地图节点上绘制的出口。
4. 确认所有方向的出口都与关卡边界对齐。

## 5. 总结

| 问题 | 根因 | 修复 |
|---|---|---|
| 出口位置偏移 | 未减去 `LevelBounds.position` | 用 `transition.position - level_bounds.position` 计算相对位置 |
| 底部出口超出/覆盖边框 | 未考虑 3 像素高的过渡块 | 底部偏移改为 `size.y - 5` |
| 代码冗余 | 每个方向重复缩放计算 | 统一计算 `pos /= SCALE_FACTOR` |

## 6. 后续建议

- 在关卡设计阶段保持 `LevelBounds` 位置规范，便于地图系统一致处理。
- 考虑将地图节点更新逻辑改为在编辑器中自动触发（如通过 `@tool` 的 setter），减少手动点击 Update 的次数。
