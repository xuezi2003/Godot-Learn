#!/usr/bin/env bash
# 更新并清理 godot-docs 文档仓库
# 功能：
#   1. 如果存在 git 仓库，先 git reset 并 git pull --depth 1 拉取最新版本
#   2. 删除非实质性内容（构建工具、模板、静态资源、GitHub 配置、证书、作者页等）
# 保留： tutorials, classes, getting_started, engine_details, community, about, img
#        以及根目录下的 index.rst
#
# 用法：在任意位置执行 ./Scripts/godot-docs-maintainer/update_godot_docs.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TARGET_DIR="${PROJECT_DIR}/godot-docs"

if [[ ! -d "${TARGET_DIR}" ]]; then
    echo "错误：未找到 ${TARGET_DIR} 目录"
    exit 1
fi

cd "${TARGET_DIR}"

echo "目标目录: ${TARGET_DIR}"
echo

# 如果存在 git 仓库，先更新到最新版本
if [[ -d ".git" ]]; then
    echo "检测到 git 仓库，开始更新..."
    echo "切换到 master 分支并强行与远端同步..."
    git fetch --depth=1 origin master
    git reset --hard origin/master
    echo "更新完成"
    echo
else
    echo "未检测到 git 仓库，跳过更新步骤"
    echo
fi

echo "开始清理 godot-docs 非实质性内容..."

# 非内容目录
NON_CONTENT_DIRS=(
    ".github"
    "_extensions"
    "_static"
    "_styleguides"
    "_templates"
    "_tools"
)

# 非内容文件（根目录）
NON_CONTENT_FILES=(
    ".editorconfig"
    ".gitattributes"
    ".gitignore"
    ".lycheeignore"
    ".mailmap"
    ".pre-commit-config.yaml"
    ".readthedocs.yml"
    "Makefile"
    "make.bat"
    "conf.py"
    "pyproject.toml"
    "requirements.txt"
    "robots.txt"
    # 以下是与文档正文无关的文件
    "404.rst"
    "AUTHORS.md"
    "LICENSE.txt"
    "README.md"
    "about/complying_with_licenses.rst"
    "engine_details/architecture/files/class_tree.zip"
)

BEFORE_SIZE=$(du -sh "${TARGET_DIR}" | cut -f1)
echo "清理前大小: ${BEFORE_SIZE}"
echo

for dir in "${NON_CONTENT_DIRS[@]}"; do
    path="${TARGET_DIR}/${dir}"
    if [[ -d "${path}" ]]; then
        rm -rf "${path}"
        echo "已删除目录: ${dir}"
    fi
done

for file in "${NON_CONTENT_FILES[@]}"; do
    path="${TARGET_DIR}/${file}"
    if [[ -f "${path}" ]]; then
        rm -f "${path}"
        echo "已删除文件: ${file}"
    fi
done

AFTER_SIZE=$(du -sh "${TARGET_DIR}" | cut -f1)
echo
echo "清理完成"
echo "清理前大小: ${BEFORE_SIZE}"
echo "清理后大小: ${AFTER_SIZE}"
echo

echo "保留的实质性内容目录:"
for dir in about classes community engine_details getting_started img tutorials; do
    if [[ -d "${TARGET_DIR}/${dir}" ]]; then
        size=$(du -sh "${TARGET_DIR}/${dir}" | cut -f1)
        files=$(find "${TARGET_DIR}/${dir}" -type f \( -name '*.rst' -o -name '*.md' \) | wc -l)
        printf "  %-20s %6s  (%s 篇文档)\n" "${dir}/" "${size}" "${files}"
    fi
done

# 记录更新时间
UPDATE_RECORD="${SCRIPT_DIR}/last_update.json"
cat > "${UPDATE_RECORD}" <<EOF
{
  "updated_at": "$(date -Iseconds)"
}
EOF
echo "更新记录已写入: ${UPDATE_RECORD}"
