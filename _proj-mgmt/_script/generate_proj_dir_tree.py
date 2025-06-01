import os
import subprocess
import yaml
from collections import OrderedDict

OUTPUT_FILE = "_proj-mgmt/_script/_output/proj_dir_tree.yml"

def is_ignored(path):
    """`.gitignore` に従って無視対象を判定"""
    try:
        result = subprocess.run(
            ["git", "check-ignore", path],
            capture_output=True,
            text=True
        )
        return result.returncode == 0
    except Exception:
        return False

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
            current = current.setdefault(part, OrderedDict())

        # ファイルを追加
        for filename in filenames:
            rel_file = os.path.join(rel_dir, filename) if rel_dir else filename
            if not is_ignored(rel_file):
                current[filename] = f'"{os.path.join(rel_dir, filename)}"'

        # 空ディレクトリ対応
        if not filenames and not dirnames:
            current.clear()
            current.update([])

    return tree

def sort_dirs_first(d):
    """ディレクトリ→ファイルの順に並び替え"""
    if isinstance(d, dict):
        dirs = {}
        files = {}
        for k, v in d.items():
            if isinstance(v, dict) or isinstance(v, list):
                dirs[k] = sort_dirs_first(v)
            else:
                files[k] = v
        return OrderedDict(sorted(dirs.items()) + sorted(files.items()))
    return d

def move_root_files_to_end(tree):
    if "root_files" in tree:
        root = tree.pop("root_files")
        tree["root_files"] = root
    return tree

def save_yaml(data, out_path):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        yaml.dump(data, f, allow_unicode=True, sort_keys=False, default_flow_style=False)
        f.write("# （省略）= 空ディレクトリ\n")

if __name__ == "__main__":
    tree = build_tree(".")
    tree = sort_dirs_first(tree)
    tree = move_root_files_to_end(tree)
    save_yaml(tree, OUTPUT_FILE)
    print(f"✅ Directory tree saved to: {OUTPUT_FILE}")

