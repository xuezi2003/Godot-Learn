# 05 道具 Buff 系统

## 道具系统概述

游戏中三种道具：

- 提升移动速度
- 提升射击频率
- 进入武装强化状态（螺旋射击）

敌人被击杀后按权重概率掉落。

## 物理层设计

### 物理层作用

物理层在引擎层面对碰撞对象进行筛选，只有符合规则的目标才会传递到脚本层。避免在脚本中写大量 `if` 过滤，也避免敌人拾取道具、子弹击毁道具等错误交互。

### Layer 与 Mask

- **Layer**：我属于哪一类。
- **Mask**：我关心哪一类，会主动与哪一类发生交互。

### 项目物理层命名

打开 **Project > Project Settings > 2D Physics > Layer Names**，设置以下 7 层：

| 层级 | 名称 | 用途 |
|-----|------|------|
| 1 | world | 地图、墙壁、障碍物、空气墙，限制玩家、敌人、子弹移动 |
| 2 | player | 玩家本体 |
| 3 | enemy_body | 敌人碰撞实体，与世界产生物理阻挡 |
| 4 | enemy_sensor | 敌人伤害检测区域，检测是否碰到玩家 |
| 5 | bullet | 子弹 |
| 6 | pick_up | 道具 |
| 7 | explosion | 敌人自爆范围，伤害玩家和周围敌人 |

为什么把敌人拆成 `enemy_body` 和 `enemy_sensor`？

- `enemy_body`：负责与地图的物理阻挡。
- `enemy_sensor`：负责检测接触伤害。
- 职责不同，拆开后逻辑更清晰。

### 物理层划分思路

1. 列出游戏中的对象身份：玩家、敌人、子弹、障碍物、道具等。
2. 列出它们之间需要发生的关系：玩家撞墙、子弹打敌人、玩家拾取道具、敌人碰玩家等。
3. 把不同职责的碰撞拆开，如敌人的身体与伤害检测区域。

### 玩家与子弹的层级设置

**Player 根节点：**

- Layer：`player`（第 2 层）
- Mask：`world`（第 1 层）

> 玩家不需要勾选 `enemy_body` 或 `enemy_sensor`。CharacterBody2D 的 Mask 决定移动时被哪些障碍物挡住。玩家被敌人伤害属于触发检测，由敌人的 Area2D 主动检测并调用玩家受伤接口。

**Bullet 根节点：**

- Layer：`bullet`（第 5 层）
- Mask：`world`（第 1 层）

> 子弹命中敌人由敌人的 Area2D 检测子弹，而不是子弹去检测敌人，避免命中逻辑被触发两次。子弹脚本中的 `WORLD_COLLISION_MASK` 常量用于射线检测防止穿过薄障碍物，与节点属性上的 Mask 不同。

## 资源配置驱动设计

### 设计思路

道具的共同逻辑（如何刷新、渲染、碰撞、拾取）由场景和脚本统一处理；差异化的效果（持续时间、数值强度、形态切换）由 Resource 配置。

优势：

- 新增道具只需创建配置资源。
- 调整参数在编辑器中完成，不需要改代码。

### 道具图标 AtlasTexture

1. 在 `resources` 下新建 `atlases` 文件夹。
2. 右键新建资源，搜索 **AtlasTexture**。
3. 创建三个资源：
   - `pick_up_rapid`：射速提升图标
   - `pick_up_speed`：移速提升图标
   - `pick_up_spiral`：螺旋强化图标
4. 选择 `props_ui.png`，编辑区域选取对应图标。
5. 如果相邻道具被自动合并，切换为栅格吸附，按 8×8 或 16×16 选取。

### 道具配置脚本

在 `resources/config` 下创建 `pick_up_config.gd`，继承 **Resource**：

```gdscript
class_name PickUpConfig
extends Resource

enum PickUpType {
    RAPID_FIRE,
    SPEED_BOOST,
    SPIRAL_MODE
}

enum PlayerForm {
    NORMAL,
    ARMED
}

enum FirePattern {
    DIRECTIONAL,
    SPIRAL
}

@export_group("基础信息")
@export var pick_up_type: PickUpType
@export var display_name: String
@export_range(0, 100) var drop_weight: int = 1
@export var icon_texture: Texture2D

@export_group("效果数值")
@export var duration: float = 5.0
@export var move_speed_multiplier: float = 1.0
@export var fire_rate_multiplier: float = 1.0

@export_group("形态与弹幕")
@export var form: PlayerForm = PlayerForm.NORMAL
@export var fire_pattern: FirePattern = FirePattern.DIRECTIONAL
```

- 字段设计考虑的是 Buff 生效涉及的数据维度，而不是具体有多少种 Buff。
- 形态和弹幕效果拆分为两个字段，方便后续独立控制。

### 创建具体配置资源

在 `resources/config` 下新建资源，类型选择 `PickUpConfig`，创建三个：

- `pick_up_rapid`：移速倍率 1.0，射速倍率 2.0，掉落权重 2
- `pick_up_speed`：移速倍率 1.5，射速倍率 1.0
- `pick_up_spiral`：形态 `ARMED`，弹幕 `SPIRAL`，射速倍率 20.0

## 道具场景

1. 在 `scene` 下新建场景，根节点选择 **Area2D**。
2. 命名为 `pick_up`。
3. 添加子节点：
   - **CollisionShape2D**：Shape 选择 **CircleShape2D**，Radius 6
   - **Sprite2D**：显示道具图标
   - **Timer**：命名为 `LifeTimer`，Wait Time 5 秒

### 闪烁效果 Shader

1. 在 `scene` 下创建 Shader 资源 `blink.gdshader`，模式选择 **Canvas Item**。

```glsl
shader_type canvas_item;

uniform bool blink_enabled = false;
uniform float blink_speed = 6.0;
uniform float hidden_ratio = 0.5;

void fragment() {
    COLOR = texture(TEXTURE, UV);
    if (blink_enabled) {
        float cycle = fract(TIME * blink_speed);
        if (cycle < hidden_ratio) {
            COLOR.a = 0.0;
        }
    }
}
```

2. 选中 Sprite2D，在 **CanvasItem > Material** 中新建 **ShaderMaterial**。
3. 加载 `blink.gdshader`。
4. 勾选 **Local to Scene**，否则所有道具会共享同一材质，导致同时闪烁。

### 道具脚本

```gdscript
class_name PickUp
extends Area2D

const BLINK_ENABLED := "blink_enabled"

@export var config: PickUpConfig

@onready var sprite: Sprite2D = $Sprite2D
@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    life_timer.timeout.connect(_on_life_timer_timeout)
    update_icon()
    life_timer.start()

func _process(delta: float) -> void:
    if life_timer.time_left <= 2.0 and not _is_blinking():
        set_blinking(true)

func update_icon() -> void:
    if config == null:
        return
    sprite.texture = config.icon_texture

func _on_body_entered(body: Node2D) -> void:
    if config == null:
        return
    if not body is Player:
        return
    var player := body as Player
    if player.apply_pickup(config):
        queue_free()

func _on_life_timer_timeout() -> void:
    queue_free()

func set_blinking(enabled: bool) -> void:
    var material := sprite.material as ShaderMaterial
    if material != null:
        material.set_shader_parameter(BLINK_ENABLED, enabled)

func _is_blinking() -> bool:
    var material := sprite.material as ShaderMaterial
    if material == null:
        return false
    return material.get_shader_parameter(BLINK_ENABLED)
```

### 道具碰撞层级

- Layer：`pick_up`（第 6 层）
- Mask：`player`（第 2 层）

## Player 应用 Buff

### 添加 class_name

在 `player.gd` 顶部添加：

```gdscript
class_name Player
```

### 新增变量

```gdscript
const DEFAULT_MOVE_SPEED_MULTIPLIER := 1.0
const DEFAULT_FIRE_RATE_MULTIPLIER := 1.0

var current_move_speed_multiplier := DEFAULT_MOVE_SPEED_MULTIPLIER
var rapid_fire_rate_multiplier: float = DEFAULT_FIRE_RATE_MULTIPLIER
var form_fire_rate_multiplier: float = DEFAULT_FIRE_RATE_MULTIPLIER

var move_speed_buff_time := 0.0
var rapid_fire_buff_time := 0.0
var form_buff_time := 0.0
```

### apply_pickup 方法

```gdscript
func apply_pickup(config: PickUpConfig) -> bool:
    if config == null:
        return false

    var applied := false
    var buff_duration := maxf(config.duration, 0.0)

    var has_form_buff := config.form == PickUpConfig.PlayerForm.ARMED or config.fire_pattern == PickUpConfig.FirePattern.SPIRAL
    var has_rapid_fire_buff := not is_equal_approx(config.fire_rate_multiplier, DEFAULT_FIRE_RATE_MULTIPLIER)

    if not is_equal_approx(config.move_speed_multiplier, DEFAULT_MOVE_SPEED_MULTIPLIER):
        current_move_speed_multiplier = config.move_speed_multiplier
        move_speed_buff_time = buff_duration
        applied = true

    if has_rapid_fire_buff and not has_form_buff:
        rapid_fire_rate_multiplier = config.fire_rate_multiplier
        rapid_fire_buff_time = buff_duration
        applied = true

    if has_form_buff:
        if config.form == PickUpConfig.PlayerForm.ARMED:
            current_form_mode = PLAYER_FORM_MODE_ARMED
        if config.fire_pattern == PickUpConfig.FirePattern.SPIRAL:
            current_shot_pattern = SHOT_PATTERN_SPIRAL
        form_fire_rate_multiplier = config.fire_rate_multiplier
        form_buff_time = buff_duration
        spiral_phase = 0.0
        applied = true

    return applied
```

- 使用 `is_equal_approx()` 比较浮点数，避免精度问题。
- 普通射速 Buff 和形态强化 Buff 分开管理，避免相互覆盖。
- 形态强化时重置螺旋相位，让效果更可控。

### 获取有效移速

```gdscript
func get_effective_move_speed() -> float:
    return move_speed * current_move_speed_multiplier
```

> 射击间隔由 04 中已有的 `_get_effective_fire_interval()` 处理，不需要重复定义。

### 更新 Buff 效果

在 `_physics_process` 开头调用：

```gdscript
update_pickup_effects(delta)
```

实现：

```gdscript
func update_pickup_effects(delta: float) -> void:
    if move_speed_buff_time > 0.0:
        move_speed_buff_time -= delta
        if move_speed_buff_time <= 0.0:
            current_move_speed_multiplier = DEFAULT_MOVE_SPEED_MULTIPLIER

    if rapid_fire_buff_time > 0.0:
        rapid_fire_buff_time -= delta
        if rapid_fire_buff_time <= 0.0:
            rapid_fire_rate_multiplier = DEFAULT_FIRE_RATE_MULTIPLIER

    if form_buff_time > 0.0:
        form_buff_time -= delta
        if form_buff_time <= 0.0:
            current_form_mode = PLAYER_FORM_MODE_NORMAL
            current_shot_pattern = SHOT_PATTERN_NORMAL
            form_fire_rate_multiplier = DEFAULT_FIRE_RATE_MULTIPLIER
```

### 移动速度应用 Buff

将 `_physics_process` 中的移动代码改为：

```gdscript
velocity = move_input * get_effective_move_speed()
```

## 测试

1. 在 `game` 场景中实例化三个 `pick_up` 场景。
2. 在 Inspector 中分别为它们赋值三种配置资源。
3. 运行测试拾取效果。
4. 测试完毕后从 `game` 场景中删除测试道具。

## 下节预告

下一节开始制作敌人系统。
