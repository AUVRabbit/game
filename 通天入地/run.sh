#!/usr/bin/env bash
# 通天入地 · 启动脚本
# 作用：首次运行时预导入 Godot 资源并生成 .godot 类缓存，避免 class_name 未注册 / Autoload 实例化失败
# 用法：
#   ./run.sh                  正常运行游戏
#   ./run.sh headless         以无头模式启动
#   ./run.sh import           仅执行资源预导入（首次运行或升级 Godot 后执行一次即可）
#   ./run.sh editor           启动 Godot 编辑器

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# 查找 Godot 可执行文件：依次尝试 PATH / Steam 安装 / Linux 下载版 / macOS 常见路径
find_godot() {
    if command -v godot &>/dev/null; then
        echo "godot"
        return 0
    fi
    local candidates=(
        "/tmp/Godot_v4.7.2-stable_linux.x86_64"
        "/usr/local/bin/godot"
        "$HOME/.steam/steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot"
        "$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot"
        "C:/Program Files/Godot/Godot_v4.7.2-stable_win64.exe"
    )
    local p
    for p in "${candidates[@]}"; do
        if [ -x "$p" ] || [ -f "$p" ]; then
            echo "$p"
            return 0
        fi
    done
    echo ""
    return 1
}

GODOT_BIN="$(find_godot)"

if [ -z "$GODOT_BIN" ]; then
    echo "[run.sh] 未找到 Godot 可执行文件。"
    echo "请先安装 Godot 4.7.2 并将可执行文件加入 PATH，或下载到 /tmp/Godot_v4.7.2-stable_linux.x86_64"
    exit 1
fi

echo "[run.sh] 使用 Godot: $GODOT_BIN"

# 首次运行：若 .godot/ 不存在或缺少类缓存文件，则以编辑器模式导入一次
NEEDS_IMPORT=false
if [ ! -d ".godot" ]; then
    NEEDS_IMPORT=true
elif [ ! -f ".godot/global_script_class_cache.cfg" ]; then
    NEEDS_IMPORT=true
fi

do_import() {
    echo "[run.sh] 首次运行 · 预导入资源并生成 .godot 类缓存..."
    "$GODOT_BIN" --headless --editor --path "$PROJECT_DIR" --quit-after 60 2>&1 | tail -3 || true
    echo "[run.sh] 导入完成。"
}

case "${1:-run}" in
    import)
        do_import
        exit 0
        ;;
    headless)
        [ "$NEEDS_IMPORT" = "true" ] && do_import
        exec "$GODOT_BIN" --headless --path "$PROJECT_DIR"
        ;;
    editor)
        [ "$NEEDS_IMPORT" = "true" ] && do_import
        exec "$GODOT_BIN" --editor --path "$PROJECT_DIR"
        ;;
    run)
        [ "$NEEDS_IMPORT" = "true" ] && do_import
        exec "$GODOT_BIN" --path "$PROJECT_DIR"
        ;;
    *)
        echo "用法：$0 {run|headless|import|editor}"
        exit 1
        ;;
esac
