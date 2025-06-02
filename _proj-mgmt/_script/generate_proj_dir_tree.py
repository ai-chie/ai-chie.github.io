# 📁 generate_proj_dir_tree.py（フロー形式 [ファイル名, パス] 対応 + ソート修正）
# ファイルは [ファイル名, パス]、ディレクトリは {dirname: [...]} のリスト形式でネスト出力

import os
import subprocess
from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedSeq, CommentedMap

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

# --- 並べ替え: ディレクトリ→ファイル、アルファベット順 ---
def sort_entries(entries):
    dirs = []
    files = []
    for entry in entries:
        if isinstance(entry, dict):
            dirs.append(entry)
        else:
            files.append(entry)
    return sorted(dirs, key=lambda x: list(x.keys())[0]) + sorted(files, key=lambda x: str(x[0]))

# --- 再帰的に構造を混在リスト形式で構築（相対パス引き継ぎ） ---
def build_tree(path, prefix=""):
    entries = []
    try:
        for name in sorted(os.listdir(path)):
            full_path = os.path.join(path, name)
            rel_path = os.path.join(prefix, name).replace("\\", "/")
            if is_ignored(rel_path):
                continue
            if os.path.isdir(full_path):
                subentries = build_tree(full_path, rel_path)
                subentries = sort_entries(subentries)
                if not subentries:
                    empty = CommentedSeq()
                    empty.yaml_add_eol_comment("（省略）", 0)
                    entries.append({name: empty})
                else:
                    entries.append({name: subentries})
            else:
                item = CommentedSeq([name, rel_path])
                item.fa.set_flow_style()
                entries.append(item)
    except Exception:
        pass
    return sort_entries(entries)

# --- トップレベル構造構築（辞書で開始） ---
def build_root_tree():
    root = CommentedMap()
    try:
        for name in sorted(os.listdir(".")):
            if is_ignored(name):
                continue
            full_path = os.path.join(".", name)
            if os.path.isdir(full_path):
                subtree = build_tree(full_path, name)
                subtree = sort_entries(subtree)
                if not subtree:
                    empty = CommentedSeq()
                    empty.yaml_add_eol_comment("（省略）", 0)
                    root[name] = empty
                else:
                    root[name] = subtree
            else:
                rel_path = name.replace("\\", "/")
                item = CommentedSeq([name, rel_path])
                item.fa.set_flow_style()
                root.setdefault("root_files", CommentedSeq()).append(item)
        if "root_files" in root:
            rf = root.pop("root_files")
            root["root_files"] = sorted(rf, key=lambda x: str(x[0]))
    except Exception:
        pass
    return root

# --- YAML保存 ---
def save_yaml(data, out_path):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    yaml = YAML()
    yaml.default_flow_style = False
    yaml.allow_unicode = True
    yaml.width = 4096
    with open(out_path, "w", encoding="utf-8") as f:
        yaml.dump(data, f)

# --- 実行 ---
if __name__ == "__main__":
    tree = build_root_tree()
    save_yaml(tree, OUTPUT_FILE)
    print(f"✅ Directory tree saved to: {OUTPUT_FILE}")
