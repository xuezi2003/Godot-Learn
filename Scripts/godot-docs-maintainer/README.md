# godot-docs 维护脚本

这组脚本用于自动维护项目中的 `godot-docs/` 文档仓库。

## 文件说明

| 文件 | 作用 |
|------|------|
| `update_godot_docs.sh` | 主脚本：git 更新并删除非实质性内容 |

## 使用方式

```bash
./Scripts/godot-docs-maintainer/update_godot_docs.sh
```

## 处理流程

1. **git 更新**
   - `git reset --hard HEAD`
   - `git pull --depth 1`

2. **结构精简**
   - 删除 `.github/`、`_static/`、`_extensions/` 等非内容目录
   - 删除 `Makefile`、`conf.py`、`requirements.txt` 等构建配置文件
   - 删除 `LICENSE.txt`、`AUTHORS.md`、`README.md`、`404.rst` 等元数据文件
   - 删除 `about/complying_with_licenses.rst`
   - 删除 `engine_details/architecture/files/class_tree.zip`

## 保留内容

- `tutorials/`、`classes/`、`getting_started/`、`engine_details/`、`community/`、`about/`、`img/`
- 根目录下的 `index.rst`（文档总入口）
