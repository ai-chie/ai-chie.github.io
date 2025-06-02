# 📁 generate_proj_dir_tree.py（理想形式出力対応・構造修正版）
# ディレクトリ構造をネスト辞書で正しく出力

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

# --- 再帰的に構造を辞書形式で構築 ---
def build_dict(path):
    structure = {}
    files = []
    try:
        for name in sorted(os.listdir(path)):
            rel_path = os.path.join(path, name).replace("\\", "/")
            if is_ignored(rel_path):
                continue
            if os.path.isdir(rel_path):
                nested = build_dict(rel_path)
                structure[name] = nested if nested else []
            else:
                files.append([name, rel_path])
    except Exception:
        return []
    if files:
        file_dict = {f[0]: f[1] for f in files}  # 使わないが明示的整理可
        structure.update({f[0]: f[1] for f in files})
    return structure if structure else []

# --- トップレベルを辞書構造に ---
def build_root_tree():
    tree = {}
    root_files = []
    for name in sorted(os.listdir(".")):
        if is_ignored(name):
            continue
        path = name.replace("\\", "/")
        if os.path.isdir(path):
            nested = build_dict(path)
            tree[name] = nested if nested else []
        else:
            root_files.append([name, path])
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
    tree = build_root_tree()
    save_yaml(tree, OUTPUT_FILE)
    print(f"✅ Directory tree saved to: {OUTPUT_FILE}")
