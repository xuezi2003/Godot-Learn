# 07 枚举与 Match

## 枚举

**枚举（enum）** 是为游戏定义标签或状态的便捷方式。例如一款有很多单位的游戏，需要把每个单位标记为友军、中立或敌对。

### 定义与使用

在脚本顶部用 `enum` 定义，并给它起个名字（便于组织）：

```gdscript
enum Alignment {ALLY, NEUTRAL, ENEMY}

var unit_alignment = Alignment.ALLY

func _ready():
    if unit_alignment == Alignment.ENEMY:
        print("你不受欢迎")
    else:
        print("欢迎")
```

通过 `Alignment.ALLY` 这样的方式访问状态。相比用字符串或整数表示状态，枚举**更安全**：拼错状态名时 Godot 会直接报错。

### 标记 @export 变量

枚举可以用来标记导出变量，从而在检查器中以下拉菜单选择：

```gdscript
@export var unit_alignment: Alignment
```

### 枚举的底层：递增常量

幕后，Godot 为枚举中的每个状态创建一个**常量**，默认值从 `0` 开始递增：

```gdscript
enum Alignment {ALLY, NEUTRAL, ENEMY}
# 等价于 ALLY = 0, NEUTRAL = 1, ENEMY = 2

print(Alignment.ENEMY)     # 2（ENEMY 是第三个状态）
```

也可以**覆盖默认值**：

```gdscript
enum Alignment {ALLY = 1, NEUTRAL = 0, ENEMY = -1}
print(Alignment.ENEMY)     # -1
```

## Match

`match` 是 Godot 中类似其他语言 **switch** 的语句，可根据变量的值执行不同代码，与枚举配合得非常好。

```gdscript
match my_alignment:
    Alignment.ALLY:
        print("hello, friend")
    Alignment.NEUTRAL:
        print("I come in peace")
    Alignment.ENEMY:
        print("taste my wrath")
    _:
        print("who art thou")   # 默认分支，用下划线表示
```

用下划线 `_` 作为分支，可以处理「不匹配上面任何情况」的默认响应。若把 `my_alignment` 设为 `Alignment.ENEMY`，就会打印 `taste my wrath`。
