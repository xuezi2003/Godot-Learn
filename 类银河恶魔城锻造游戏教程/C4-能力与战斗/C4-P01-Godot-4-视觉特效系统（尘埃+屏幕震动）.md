# C4-P01：Godot 4 视觉特效系统（尘埃 + 屏幕震动）

> 本集建立一个全局可视化的”工厂”系统，让玩家、敌人或任何实体都能用一行代码触发尘埃与屏幕震动效果，避免在每个场景中重复实例化特效。

## 1. 问题与思路

- 直接做法：玩家在落地时自己生成尘埃效果。
- 问题：多个实体（玩家、敌人、掉落物）都需要同样效果时，实例化、控制、播放逻辑会分散在多处。
- 解决方案：**视觉特效工厂（Visual Effects Manager）**
  - 全局 Autoload 脚本，负责创建并设置特效实例。
  - 任何实体只需调用一行代码即可请求特效。
  - 修改工厂内部即可影响所有调用方。

## 2. 准备工作

1. 导入第四章资源包中的尘埃精灵与可破坏道具纹理。
2. 新建全局脚本 `VisualEffects.gd` 并加入 **项目设置 → 自动加载**。

## 3. 尘埃效果

### 1. 创建 `DustEffect` 场景

- 根节点为 `Sprite2D`。
- 纹理为 8×3 的精灵表：
  - 第一行：跳跃尘埃
  - 第二行：落地尘埃
  - 第三行：受击尘埃
- 添加 `AnimationPlayer`，分别制作 `jump`、`land`、`hit` 三个动画，每段约 0.4 秒。

### 2. `DustEffect.gd` 脚本要点

```gdscript
extends Sprite2D
class_name DustEffect

enum Type { JUMP, LAND, HIT }

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func start(type: Type) -> void:
    var anim_name := "jump"
    match type:
        Type.JUMP:
            anim_name = "jump"
            position.y -= 14
        Type.LAND:
            anim_name = "land"
            position.y += 16
        Type.HIT:
            anim_name = "hit"
            rotation_degrees = randi_range(0, 3) * 90
    animation_player.play(anim_name)
    await animation_player.animation_finished
    queue_free()
```

- 注意把根节点的 **Z Index** 设为 `2`，避免被关卡遮挡。

### 3. `VisualEffects.gd` 工厂

```gdscript
extends Node
class_name VisualEffects

const DUST_EFFECT := preload("res://.../dust_effect.tscn")

func _spawn_dust_effect(pos: Vector2) -> DustEffect:
    var dust: DustEffect = DUST_EFFECT.instantiate()
    add_child(dust)
    dust.global_position = pos
    return dust

func spawn_jump_dust(pos: Vector2) -> void:
    _spawn_dust_effect(pos).start(DustEffect.Type.JUMP)

func spawn_land_dust(pos: Vector2) -> void:
    _spawn_dust_effect(pos).start(DustEffect.Type.LAND)

func spawn_hit_dust(pos: Vector2) -> void:
    _spawn_dust_effect(pos).start(DustEffect.Type.HIT)
```

- 基础函数 `_spawn_dust_effect` 用下划线表示“仅供内部使用”。
- 外部只需调用 `VisualEffects.spawn_jump_dust(global_position)` 等。

### 4. 在玩家状态中使用

- **跳跃状态 `enter`**：调用 `VisualEffects.spawn_jump_dust(player.global_position)`。
- **下落状态落地检测处**：调用 `VisualEffects.spawn_land_dust(player.global_position)`。

## 4. 屏幕震动

### 1. 在 `VisualEffects` 中发射信号

```gdscript
signal camera_shook(strength: float)

func shake_camera(strength: float = 1.0) -> void:
    camera_shook.emit(strength)
```

- 虽然不完全符合“工厂”模式，但作为一种视觉相关的消息总线非常便利。

### 2. 玩家相机脚本 `PlayerCamera.gd`

```gdscript
extends Camera2D
class_name PlayerCamera

var shake_strength: float = 0.0
@export var shake_decay: float = 5.0
@export var max_shake_offset: float = 20.0

func _ready() -> void:
    VisualEffects.camera_shook.connect(_on_camera_shook)

func _on_camera_shook(strength: float) -> void:
    shake_strength = min(shake_strength + strength, max_shake_offset)

func _process(delta: float) -> void:
    if shake_strength > 0.0:
        offset = Vector2(
            randf_range(-shake_strength, shake_strength),
            randf_range(-shake_strength, shake_strength)
        )
        shake_strength = lerpf(shake_strength, 0.0, shake_decay * delta)
    else:
        offset = Vector2.ZERO
```

- 使用 `Camera2D.offset` 偏移，不会移动相机本体，避免干扰跟随逻辑。
- 注意边界外的瓦片，避免震动时露出灰色背景。

## 5. 测试与扩展

- 可在 `PlayerHUD` 中临时添加按钮（使用内置脚本）测试尘埃与震动。
- 家庭作业：用第三章的音频系统或 `AudioStreamPlayer2D` 为跳跃/落地添加空间音效。
- 性能提示：大量特效时可考虑对象池，但 Godot 4 实例化小场景效率较高，本项目暂不采用。
