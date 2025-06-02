# 📁 generate_proj_dir_tree.py
# 場所: _proj-mgmt/_script/

import os
import subprocess
from ruamel.yaml import YAML
from collections import OrderedDict

OUTPUT_FILE = "_proj-mgmt/_script/_output/proj_dir_tree.yml"
EXCLUDE_NAMES = {".git", ".github", ".gitignore", ".DS_Store", "node_modules"}

# --- 除外チェック（.gitignore + ハードコード） ---
def is_ignored(path):
    name = os.path.basename(path)
    if name in EXCLUDE_NAMES:
        return True
    try:
        result = subprocess.run(["git", "check-ignore", path], capture_output=True, text=True)
        return result.returncode == 0
    except Exception:
        return False

# --- ディレクトリ構造を構築 ---
def build_tree(base_dir):
    def walk_dir(path):
        entries = []
        full_path = os.path.abspath(path)
        try:
            for name in sorted(os.listdir(full_path)):
                rel_path = os.path.join(path, name)
                if is_ignored(rel_path):
                    continue
                abs_entry = os.path.join(full_path, name)
                if os.path.isdir(abs_entry):
                    sub = walk_dir(rel_path)
                    entries.append(OrderedDict([(name, sub if sub else [])]))
                else:
                    entries.append([name, rel_path.replace("\\", "/")])
        except Exception:
            pass
        return entries

    tree = OrderedDict()
    for name in sorted(os.listdir(base_dir)):
        if name in EXCLUDE_NAMES:
            continue
        path = os.path.join(base_dir, name)
        if os.path.isdir(path):
            tree[name] = walk_dir(name)
        else:
            tree.setdefault("root_files", []).append([name, name])
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
    if "root_files" in tree:
        root_files = tree.pop("root_files")
        tree["root_files"] = root_files  # root_filesを末尾に
    save_yaml(tree, OUTPUT_FILE)
    print(f"✅ Directory tree saved to: {OUTPUT_FILE}")
