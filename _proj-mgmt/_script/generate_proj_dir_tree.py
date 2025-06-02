# 📁 generate_proj_dir_tree.py（理想形式出力対応版）
# リポジトリ全体を走査し、以下の形式でYAML出力：
#
# _posts:
#   ja:
#     - [index.html, _posts/ja/index.html]
#     - categories:
#         - [index.html, _posts/ja/categories/index.html]
#     - tags:
#         - [index.html, _posts/ja/tags/index.html]
# root_files:
#   - [README.md, README.md]

import os
import subprocess
from ruamel.yaml import YAML

OUTPUT_FILE = "_proj-mgmt/_script/_output/proj_dir_tree.yml"
EXCLUDE_NAMES = {".git", ".github", ".gitignore", ".DS_Store", "node_modules"}

# --- 除外チェック（.gitignore + 明示除外） ---
def is_ignored(path):
    name = os.path.basename(path)
    if name in EXCLUDE_NAMES:
        return True
    try:
        result = subprocess.run(["git", "check-ignore", path], capture_output=True, text=True)
        return result.returncode == 0
    except Exception:
        return False

# --- ディレクトリ構造を再帰的に構築 ---
def walk(path):
    entries = []
    try:
        for name in sorted(os.listdir(path)):
            rel_path = os.path.join(path, name).replace("\\", "/")
            if is_ignored(rel_path):
                continue
            if os.path.isdir(rel_path):
                sub = walk(rel_path)
                entries.append({name: sub if sub else []})
            else:
                entries.append([name, rel_path])
    except Exception:
        pass
    return entries

# --- ルート構造を構築（ディレクトリ + root_files分離） ---
def build_tree(root_dir):
    tree = {}
    root_files = []
    for name in sorted(os.listdir(root_dir)):
        rel_path = os.path.join(root_dir, name).replace("\\", "/")
        if is_ignored(name):
            continue
        if os.path.isdir(rel_path):
            sub_tree = walk(rel_path)
            tree[name] = sub_tree if sub_tree else []
        else:
            root_files.append([name, name])
    if root_files:
        tree["root_files"] = root_files
    return tree

# --- YAML保存 ---
def save_yaml(data, out_path):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    yaml = YAML()
    yaml.default_flow_style = False
    yaml.allow_unicode = True
    yaml.width = 4096
    with open(out_path, "w", encoding="utf-8") as f:
        yaml.dump(data, f)
        f.write("# （省略）= 空ディレクトリ\n")

# --- 実行 ---
if __name__ == "__main__":
    tree = build_tree(".")
    save_yaml(tree, OUTPUT_FILE)
    print(f"✅ Directory tree saved to: {OUTPUT_FILE}")
