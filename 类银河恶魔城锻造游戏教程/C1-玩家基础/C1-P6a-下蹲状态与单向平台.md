# C1-P6a：下蹲状态与单向平台

> 实现下蹲状态，调整碰撞形状，并通过碰撞层与射线检测实现从单向平台向下跳跃。

## 1. 课后作业回顾

- James 实现了下蹲并向下跳跃穿过平台，但蹲下时不能起跳。
- 本集将实现：蹲下时仍可起跳，但在单向平台上蹲下起跳会向下掉落。

## 2. 创建 Crouch 状态

```
States/
├── Idle
├── Run
├── Jump
├── Fall
└── Crouch
```

- 创建 `crouch_state.gd`，继承 `PlayerState`。
- 在 `PlayerState` 中添加引用：

```gdscript
@onready var crouch: PlayerState = %Crouch
```

## 3. 进入与退出 Crouch

### 3.1 Idle / Run 中进入 Crouch

```gdscript
# idle_state.gd / run_state.gd
func process(_delta: float) -> PlayerState:
    if player.direction.y >= 0.5:
        return crouch
    # ...
    return null
```

- 使用 `direction.y >= 0.5` 防止摇杆轻微下拨误触发下蹲。

### 3.2 Crouch 中退出

```gdscript
# crouch_state.gd
func process(_delta: float) -> PlayerState:
    if player.direction.y <= 0.5:
        return idle
    return null
```

- 必须彻底松开下方向才会站起，保持下蹲的「粘滞感」。

## 4. 下蹲减速

```gdscript
@export var deceleration_rate: float = 10.0

func physics_process(delta: float) -> PlayerState:
    player.velocity.x -= player.velocity.x * deceleration_rate * delta
    return null
```

- 奔跑中蹲下会滑行一段距离后停下。
- 可调大 `deceleration_rate` 实现急停，或调小模拟冰面。

## 5. 切换碰撞形状

### 5.1 创建两个碰撞形状

- `CollisionStand`：站立碰撞（胶囊，原尺寸）。
- `CollisionCrouch`：下蹲碰撞（胶囊，高度减半，约 30 像素）。

### 5.2 设为独立实例

复制碰撞形状后，右键 → **设为唯一**，避免两个形状共享同一份数据。

### 5.3 默认启用/禁用

- 默认启用 `CollisionStand`，禁用 `CollisionCrouch`。

### 5.4 代码切换

在 `player.gd` 中引用：

```gdscript
@onready var collision_stand: CollisionShape2D = %CollisionStand
@onready var collision_crouch: CollisionShape2D = %CollisionCrouch
```

在 `crouch_state.gd` 中：

```gdscript
func enter() -> void:
    player.collision_stand.disabled = true
    player.collision_crouch.disabled = false

func exit() -> void:
    player.collision_stand.disabled = false
    player.collision_crouch.disabled = true
```

## 6. 下蹲时精灵缩放（临时）

- 进入下蹲时：`sprite.scale.y = 0.625`，`sprite.position.y = -15`。
- 退出时恢复：`scale.y = 1.0`，`position.y = -24`。
- 后续有了动画后会移除这段代码。

## 7. 单向平台

### 7.1 搭建平台

- 添加 `Sprite2D` + `StaticBody2D` + `CollisionShape2D`。
- 在 `CollisionShape2D` 中勾选 **One Way Collision**。
- 箭头向下，表示只允许从下往上穿过，站在顶部有碰撞。

### 7.2 碰撞层设置

编辑项目设置 → 2D 物理图层名称：

| 层 | 名称 |
|----|------|
| 1 | Ground |
| 2 | OneWayPlatform |

配置：

- 普通地面：`Layer = Ground`。
- 单向平台：`Layer = OneWayPlatform`，`Mask` 可不设。
- 玩家：`Layer = 无` 或 `Ground`，`Mask = Ground | OneWayPlatform`。

## 8. 检测脚下是否为单向平台

### 8.1 使用 RayCast2D

- 在玩家场景中添加 `RayCast2D`。
- 命名为 `OneWayPlatformRaycast`。
- `Target Position = (0, 4)`，只检测正下方。
- `Collision Mask = OneWayPlatform`。
- 开启 `Hit From Inside`（可选）。

### 8.2 改为 ShapeCast2D

后续发现站在平台边缘时 RayCast 可能失效，因此改用 `ShapeCast2D`：

- 使用矩形或圆形形状覆盖玩家底部区域。
- `Target Position = (0, 6)`，`Shape Size` 覆盖角色宽度。
- `Collision Mask = OneWayPlatform`。
- 默认 **禁用**，只在需要时调用 `force_shape_update()`。

```gdscript
# player.gd
@onready var one_way_platform_shapecast: ShapeCast2D = %OneWayPlatformShapecast
```

## 9. 蹲下从单向平台下落

```gdscript
# crouch_state.gd
func handle_input(event: InputEvent) -> PlayerState:
    if event.is_action_pressed("jump"):
        player.one_way_platform_shapecast.force_shapecast_update()
        if player.one_way_platform_shapecast.is_colliding():
            player.position.y += 4
            return fall
        return jump
    return null
```

- 若检测到单向平台，则向下移动 4 像素并进入 `Fall`。
- 否则正常起跳。

## 10. 课后作业

- 准备玩家精灵表：使用提供的 `hero.png`，或在 Aseprite 中创建自己的角色。
- 下一集将讲解如何在 Aseprite 中处理精灵表。
