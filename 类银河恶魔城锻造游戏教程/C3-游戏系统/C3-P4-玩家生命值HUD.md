# C3-P4：玩家生命值 HUD

> 本集构建一个全局的玩家 HUD 场景，使用 `TextureProgressBar` 与 `NinePatchRect` 实现可随玩家生命值变化动态缩放的生命条，并通过消息总线系统与玩家属性联动。

## 1. 创建 HUD 场景

### 1.1 文件夹与根节点

- 在 `Globals/` 下新建 `PlayerHUD/` 文件夹。
- 新建场景，根节点类型选择 **CanvasLayer**，命名为 `PlayerHUD`。
- 设置 `Process Mode = Always`，确保暂停时 HUD 仍能更新。

### 1.2 根节点脚本

- 为 `PlayerHUD` 附加脚本 `player_hud.gd`。
- **不要**给脚本加 `class_name`，避免与全局单例名称冲突。

### 1.3 控件结构

```
PlayerHUD (CanvasLayer)
└── Control (填满整个矩形)
    └── HPBar (MarginContainer)
        ├── HPFrame (NinePatchRect)  # 生命条外框
        └── HPBarFill (TextureProgressBar)  # 生命填充
```

- 顶层 `Control`：
  - `Mouse Filter = Ignore`，避免阻挡鼠标点击。
  - `Anchor Preset = Full Rect`。
- `HPBar`（MarginContainer）：
  - 用于控制整体尺寸和边距。
  - 设置 `Custom Minimum Size` 的最小宽度/高度。
- `HPFrame`（NinePatchRect）：
  - 使用 `health_bar_frame.png` 作为纹理。
  - 原图尺寸 40×20 像素。
  - 使用 `NinePatchRect` 的 Patch Margin 只拉伸中间纯色区域，保留边缘装饰。
  - 推荐左右 Patch Margin：27 和 7（根据实际美术调整）。
- `HPBarFill`（TextureProgressBar）：
  - 作为 `HPFrame` 的子节点。
  - `Z-Index / Order` 设置为显示在框架下方。
  - 调整位置和尺寸，使其正好位于框架内部的可填充区域。
  - 背景纹理使用黑色渐变；进度纹理使用粉红色渐变。
  - 开启 `Nine Patch Stretch`。
  - `Range` 中 `Min = 0`，`Max = 100`。

## 2. 自动加载

- 进入 **项目设置 → 自动加载**，将 `PlayerHUD` 场景添加为单例。
- 命名为 `PlayerHUD`。

## 3. HUD 脚本

### 3.1 引用节点

```gdscript
@onready var hp_bar: MarginContainer = %HPBar
@onready var hp_bar_fill: TextureProgressBar = %HPBarFill
```

### 3.2 更新生命条函数

```gdscript
func update_health_bar(current_hp: float, max_hp: float) -> void:
    var value := (current_hp / max_hp) * 100.0
    hp_bar_fill.value = value
    hp_bar.size.x = max_hp + 22  # 20 HP + 2 像素边缘装饰
```

- 每次更新时同时调整生命条宽度，使最大生命值变化时 UI 自动伸缩。

### 3.3 连接消息总线

- 在 `Messages` 中添加信号：

```gdscript
signal player_health_changed(current_hp: float, max_hp: float)
```

- 在 `PlayerHUD._ready()` 中连接：

```gdscript
func _ready() -> void:
    Messages.player_health_changed.connect(update_health_bar)
```

## 4. 玩家脚本调整

### 4.1 使用 setter 监听生命值变化

```gdscript
@export var max_hp: float = 20.0:
    set(value):
        max_hp = value
        Messages.player_health_changed.emit(hp, max_hp)

var hp: float = max_hp:
    set(value):
        hp = clamp(value, 0.0, max_hp)
        Messages.player_health_changed.emit(hp, max_hp)
```

- 通过 setter，任何对 `hp` 或 `max_hp` 的修改都会自动通知 HUD 更新。

### 4.2 调试快捷键（仅开发使用）

- 在玩家脚本的 `_unhandled_input` 中添加：

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_MINUS:
            if event.shift_pressed:
                max_hp -= 10.0
            else:
                hp -= 2.0
        elif event.keycode == KEY_EQUAL:
            if event.shift_pressed:
                max_hp += 10.0
            else:
                hp += 2.0
```

- 这些代码仅用于调试，正式发布前应移除或用 `OS.is_debug_build()` 包裹。

## 5. 测试要点

- 运行项目后左上角应显示生命条。
- 按 `-` / `=` 改变生命值，生命条应实时缩放。
- 按住 Shift 再按 `-` / `=` 改变最大生命值，生命条整体宽度应变化。

## 6. 扩展建议

- 以相同方式添加体力条、法力条或金币显示。
- 金币可使用 `Label` 直接更新数值。
- 为不同状态条添加独立的消息信号，如 `player_stamina_changed`、`player_mana_changed`。
