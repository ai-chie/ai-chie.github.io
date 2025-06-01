import os
import subprocess
import yaml
from collections import OrderedDict

OUTPUT_FILE = "_proj-mgmt/_script/_output/proj_dir_tree.yml"

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

# --- ディレクトリ構造を再帰的に構築 ---
def build_tree(root_dir):
    tree = OrderedDict()

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
            current = current.setdefault(part, OrderedDict())

        has_entry = False
        for filename in filenames:
            rel_file = os.path.join(rel_dir, filename) if rel_dir else filename
            if not is_ignored(rel_file):
                current[filename] = f'"{os.path.join(rel_dir, filename)}"'
                has_entry = True

        if not filenames and not dirnames:
            parent = tree
            for part in parts[:-1]:
                parent = parent[part]
            parent[parts[-1]] = []  # 空のディレクトリを []

    return tree

# --- ディレクトリ→ファイル順に整列 ---
def sort_dirs_first(d):
    if isinstance(d, dict):
        dirs = OrderedDict()
        files = OrderedDict()
        for k, v in sorted(d.items()):
            if isinstance(v, dict) or isinstance(v, list):
                dirs[k] = sort_dirs_first(v)
            else:
                files[k] = v
        return OrderedDict(**dirs, **files)
    return d

# --- root_files を末尾に移動 ---
def move_root_files_to_end(tree):
    if "root_files" in tree:
        root = tree.pop("root_files")
        tree["root_files"] = root
    return tree

# ✅ --- OrderedDict → 通常のdictへ再帰変換（重要） ---
def convert_ordered_to_dict(obj):
    if isinstance(obj, OrderedDict):
        return {k: convert_ordered_to_dict(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_ordered_to_dict(i) for i in obj]
    else:
        return obj

# --- YAML保存 ---
def save_yaml(data, out_path):
    data = convert_ordered_to_dict(data)  # ←ここが決定的ポイント
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        yaml.dump(
            data,
            f,
            allow_unicode=True,
            sort_keys=False,
            default_flow_style=False
        )
        f.write("# （省略）= 空ディレクトリ\n")

# --- 実行 ---
if __name__ == "__main__":
    tree = build_tree(".")
    tree = sort_dirs_first(tree)
    tree = move_root_files_to_end(tree)
    save_yaml(tree, OUTPUT_FILE)
    print(f"✅ Directory tree saved to: {OUTPUT_FILE}")
