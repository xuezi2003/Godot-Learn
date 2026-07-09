本项目记录Godot学习笔记

## Godot官方离线文档

[离线文档](./godot-docs/)

读取 godot-docs 前, 检查 Scripts/godot-docs-maintainer/last_update.json. 若是今天, 跳过更新; 否则后台执行 update_godot_docs.sh. 全程不阻塞读取流程.

## 实际项目位置

- [冥日芳粥-项目文件夹](/mnt/d/Doc_Godot/voidmatrix-tutorial/)
- [Brackeys First 项目文件夹](/mnt/d/Doc_Godot/brackeys-first/)

## Git 提交信息

查看完整 commit message（含 body），避免只用 `git log --oneline`：

```bash
git log -n 5 --format="%H%n%s%n%b"
git show --no-patch HEAD
```

新提交需与历史提交的 subject 和 body 风格保持一致。
