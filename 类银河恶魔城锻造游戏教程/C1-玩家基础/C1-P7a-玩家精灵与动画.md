# C1-P7a：玩家精灵与动画

> 本集导入角色精灵表，使用 `AnimationPlayer` 为每个状态制作动画，并实现角色朝向翻转。

## 1. 导入精灵表

- 将 `hero.png` 复制到 `Player/Sprites/`。
- 选中玩家 `Sprite2D` 节点，清空原占位纹理。
- 将 `hero.png` 拖到纹理槽。
- 在 `Sprite2D` 检查器中设置：
  - **Hframes**：16
  - **Vframes**：4

## 2. 关于动画树（AnimationTree）

- 本系列不使用 `AnimationTree`。
- 原因：
  - 已有代码状态机，一行代码即可播放对应动画。
  - `AnimationTree` 更适合 3D 或需要根据多个变量混合的复杂动画。
  - 对于本项目，直接控制 `AnimationPlayer` 更简洁。

## 3. 添加 AnimationPlayer

- 在玩家场景中添加 `AnimationPlayer` 节点。
- 创建以下动画：
  - `Idle`
  - `Run`
  - `Crouch`
  - `Jump`

## 4. 制作动画

### 4.1 基本操作

- 点击属性旁的钥匙图标添加关键帧。
- 开启「吸附到时间轴光标」，设置吸附间隔（如 `0.05` 或 `0.1`）。
- `Ctrl + 滚轮` 缩放时间轴。
- 设置动画时长。
- 创建关键帧时勾选 **创建重置轨道**（RESET Track）。
  - RESET 轨道不会在游戏运行时播放。
  - 它的作用是在编辑器中提供一键恢复默认姿态的功能，避免动画编辑过程中节点状态混乱。

### 4.2 Idle 动画

- 只需第 0 帧一个关键帧。
- 勾选 **自动播放**（Autoplay）。

### 4.3 Crouch 动画

- 时长：0.2 秒。
- 帧序列：20、21、22、23。
- 不循环。

### 4.4 Run 动画

- 时长：约 0.4–0.8 秒。
- 帧序列：14、15、16、17、18、19、12、13。
- 启用 **循环**。

> 从第 14 帧开始更接近待机动画姿态，过渡更自然。

### 4.5 Jump 动画

- 时长：1.0 秒。
- 帧序列：24、25、26、27、28。
- 不循环。

## 5. 将动画接入状态

在 `player.gd` 中引用：

```gdscript
@onready var animation_player: AnimationPlayer = %AnimationPlayer
```

在每个状态的 `enter()` 中播放：

```gdscript
# idle_state.gd
func enter() -> void:
    player.animation_player.play("Idle")

# run_state.gd
func enter() -> void:
    player.animation_player.play("Run")

# crouch_state.gd
func enter() -> void:
    player.animation_player.play("Crouch")

# jump_state.gd
func enter() -> void:
    player.animation_player.play("Jump")
```

## 6. 修复下蹲压扁问题

- 之前 `Crouch` 状态中手动修改了 `sprite.scale.y` 和 `sprite.position.y`。
- 这些代码与精灵表位置冲突，删除即可。

## 7. 角色朝向翻转

### 7.1 思路

- 所有动画默认朝右。
- 向左移动时水平翻转 `Sprite2D`。

### 7.2 实现

在 `player.gd` 的 `update_direction()` 中：

```gdscript
func update_direction() -> void:
    var previous_direction := direction
    direction = Vector2(
        Input.get_axis("left", "right"),
        Input.get_axis("up", "down")
    )

    if previous_direction.x != direction.x:
        if direction.x < 0:
            sprite.flip_h = true
        elif direction.x > 0:
            sprite.flip_h = false
```

- 只有在方向改变时才更新翻转。
- 停止移动时保持原朝向。

## 8. 碰撞形状优化

### 8.1 问题

- 矩形碰撞体在微小台阶/凸起处容易卡住。

### 8.2 解决

- 将站立和下蹲碰撞形状改为 **`CapsuleShape2D`**。
- 站立：`radius = 8`，`height = 46`。
- 下蹲：`radius = 8`，`height = 30`。

### 8.3 矩形与胶囊体对比

| 形状 | 优点 | 缺点 |
|------|------|------|
| 矩形（RectangleShape2D） | 精确贴合像素边缘 | 在斜坡/台阶边缘容易卡住 |
| 胶囊（CapsuleShape2D） | 底部圆润，能顺滑越过小凸起 | 碰撞区域比视觉稍宽/稍圆 |

- 作者建议平台游戏优先使用胶囊体，除非有特别需要精确碰撞的场景。

## 9. 单向平台检测优化

- 用 `ShapeCast2D` 替代 `RayCast2D`，覆盖角色底部区域。
- 默认禁用，只在蹲下起跳时调用 `force_shapecast_update()`。
- 减少每帧持续检测的开销。

## 10. 课后作业

- 思考如何实现基于速度的跳跃/下落动画（下集内容）。
