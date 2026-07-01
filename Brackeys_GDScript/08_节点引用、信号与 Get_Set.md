# 08 节点引用、信号与 Get/Set

## 修改节点 2.0

### 用路径引用（`$` 与 @onready）

把节点拖进脚本会生成一个 `$` 符号加节点路径。若在**释放时按住 Ctrl**，会在顶部自动生成一个带 `@onready` 的变量：

```gdscript
@onready var weapon = $Player/Weapon
```

- `@onready` 让 Godot **等所有子节点创建完毕**后再获取引用。Godot 创建节点有严格顺序，若在节点存在之前就去找它会报错。
- `$` 其实是 `get_node()` 函数的**简写**，二者等价。
- 路径是**相对**的（相对于脚本所在节点）。可以打印绝对路径：

```gdscript
print(weapon.get_path())    # 从根节点开始的完整绝对路径
```

> 路径的缺点：一旦更改路径中任何节点的名称就会失效。因此最好只在目标节点是当前节点的**子节点**时使用路径。

### 用 @export 引用节点

用 `@export` 可以在检查器中灵活指定要引用的节点，改名也不会失效：

```gdscript
@export var my_node: Node          # 可分配任意节点
# @export var my_node: Sprite2D    # 也可限定为特定类型，只能分配该类型节点
```

### 用 is 判断类型

```gdscript
func _ready():
    if my_node is Node2D:
        print("Is 2D!")
```

即使把类型限定为 `Sprite2D`，判断 `is Node2D` 仍为真——因为 **`Sprite2D` 继承自 `Node2D`**（见 [10 继承与组合](10_继承与组合.md)）。

## 信号

**信号（signal）** 是节点之间可以互相发送的消息，用来通知「某件事发生了」。它让节点在**彼此不必知晓**的情况下联系起来，非常适合给游戏的不同部分**解耦**。

### 连接内置信号

以 UI **Button** 为例：选中它 → 切到 **Node** 标签页 → 可以看到该节点的所有信号。双击 `pressed` 信号连接到脚本，会生成一个函数（函数名旁的绿色箭头表示有信号连接到它）：

```gdscript
func _on_button_pressed():
    print("money")
```

按下按钮时会发出 `pressed` 信号，所有连接到它的函数都会被调用。可以把任意多个函数连接到同一个信号。

### 自定义信号

用 `signal` 声明自己的信号，用 `.emit()` 发出。下例用一个自动倒计时的 **Timer** 节点（勾选 Autostart），其 `timeout` 信号驱动经验值增长，满级时发出 `leveled_up`：

```gdscript
signal leveled_up

var xp = 0

func _on_timer_timeout():
    xp += 5
    print(xp)
    if xp >= 20:
        xp = 0                 # 重置，进入下一级
        leveled_up.emit()      # 发出信号

func _on_leveled_up():
    print("ding")
```

### 用代码连接 / 断开

除了在编辑器里连接，也可以用代码：

```gdscript
func _ready():
    leveled_up.connect(_on_leveled_up)      # 注意：只传函数名，不要加括号

# 断开同样简单：
# leveled_up.disconnect(_on_leveled_up)
```

### 通过信号传递参数

信号可以携带参数，用于传递等级、消息等有用信息：

```gdscript
signal leveled_up(message)

func _on_leveled_up(message):
    print(message)

# 发出时传入参数：
leveled_up.emit("grads")
```

## Get / Set

**getter / setter** 让我们在变量被读取或写入时插入代码，比如把值限制在某个范围内，或在变量改变时发出信号。

### setter：写入时处理

以生命值为例，把值限制在 0~100，并在变化时发信号：

```gdscript
signal health_changed(new_health)

var health = 100:
    set(value):
        health = clamp(value, 0, 100)   # value 是试图赋给它的新值
        health_changed.emit(health)

func _on_health_changed(new_health):
    print(new_health)

func _ready():
    health = -150      # 被 clamp 限制为 0，随后发出信号，打印 0
```

### getter：读取时转换

getter 更常用于**转换值**。下例中 `chance_percentage` 始终由 `chance` 派生：

```gdscript
var chance = 0.2
var chance_percentage: int:
    get:
        return chance * 100      # 读取时返回换算后的百分比
    set(value):
        chance = float(value) / 100   # 写入时反向换算（注意类型转换）
```

- 读取 `chance_percentage`：`chance` 为 `0.2` 时得到 `20`，改为 `0.6` 时得到 `60`。
- 写入 `chance_percentage = 40`：会把 `chance` 设为 `0.4`。
