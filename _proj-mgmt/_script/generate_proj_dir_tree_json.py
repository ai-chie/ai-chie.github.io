import os
import subprocess
import json

OUTPUT_FILE = "_proj-mgmt/_script/_output/proj_dir_tree.json"

# --- .gitignore に準拠した除外チェック ---
def is_ignored(path):
    try:
        result = subprocess.run(
            ["git", "check-ignore", path],
            capture_output=True,
            text=True
        )
        return result.returncode == 0
    except Exception:
        return False

# --- ディレクトリ構造を構築（すべて通常の dict と list で） ---
def build_tree(root_dir):
    tree = {}

    for dirpath, dirnames, filenames in os.walk(root_dir):
        rel_dir = os.path.relpath(dirpath, root_dir)
        if rel_dir == ".":
            rel_dir = ""
        if is_ignored(dirpath):
            dirnames[:] = []
            continue

        dirnames.sort()
        filenames.sort()

        parts = rel_dir.split(os.sep) if rel_dir else []
        current = tree
        for part in parts:
            current = current.setdefault(part, {})

        if not filenames and not dirnames:
            parent = tree
            for part in parts[:-1]:
                parent = parent[part]
            parent[parts[-1]] = []  # 空ディレクトリ

        for filename in filenames:
            rel_file = os.path.join(rel_dir, filename) if rel_dir else filename
            if not is_ignored(rel_file):
                current[filename] = rel_file  # パスのみを値として保存

    return tree

# --- JSONとして保存 ---
def save_json(data, out_path):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"✅ JSON tree saved to: {out_path}")

# --- 実行 ---
if __name__ == "__main__":
    tree = build_tree(".")
    save_json(tree, OUTPUT_FILE)

