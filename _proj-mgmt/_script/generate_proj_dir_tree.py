# 📁 generate_proj_dir_tree.py（辞書ネスト形式・理想構造版）
# ファイルは [ファイル名, パス]、ディレクトリはキーとネストリスト形式で出力

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
def build_tree(path):
    result = {}
    try:
        entries = sorted(os.listdir(path))
        files = []
        for name in entries:
            full_path = os.path.join(path, name)
            rel_path = full_path.replace("\\", "/")
            if is_ignored(rel_path):
                continue
            if os.path.isdir(full_path):
                subtree = build_tree(full_path)
                result[name] = subtree if subtree else []
            else:
                files.append([name, rel_path])
        if files:
            result["files"] = files
    except Exception:
        pass
    return result

# --- トップレベル構造構築 ---
def build_root_tree():
    full_tree = build_tree(".")
    root_files = full_tree.pop("files", [])
    if root_files:
        full_tree["root_files"] = root_files
    return full_tree

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
