# 📁 generate_proj_dir_tree.py（辞書ベース形式修正済み）
# ファイルは [ファイル名, パス]、ディレクトリは {dirname: [...]} のリスト形式でネスト出力

import os
import subprocess
from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedSeq, CommentedMap

OUTPUT_FILE = "_proj_mgmt/script/output/proj-dir-tree.yml"
EXCLUDE_NAMES = {".git", ".gitignore", ".DS_Store", "node_modules"}

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
    dirs = CommentedMap()
    files = CommentedSeq()
    for key in sorted(entries.keys()):
        value = entries[key]
        if isinstance(value, (CommentedMap, dict)):
            dirs[key] = sort_entries(value)
        else:
            item = CommentedSeq([key, value])
            item.fa.set_flow_style()
            files.append(item)
    result = CommentedMap()
    for i, (k, v) in enumerate(dirs.items()):
        result.yaml_set_comment_before_after_key(k, before="\n")
        result[k] = v
    if files:
        result.yaml_set_comment_before_after_key("__files__", before="\n")
        result["__files__"] = files
    return result

# --- 再引的に構造を構築（相対パス引き続き） ---
def build_tree(path, prefix=""):
    entries = CommentedMap()
    try:
        for name in sorted(os.listdir(path)):
            full_path = os.path.join(path, name)
            rel_path = os.path.join(prefix, name).replace("\\", "/")
            if is_ignored(rel_path):
                continue
            if os.path.isdir(full_path):
                subentries = build_tree(full_path, rel_path)
                if not subentries:
                    empty = CommentedSeq()
                    empty.yaml_add_eol_comment("（省略）", 0)
                    entries[name] = empty
                else:
                    entries[name] = subentries
            else:
                entries[name] = rel_path
    except Exception:
        pass
    return entries

# --- トップレベル構造構築（辞書で開始） ---
def build_root_tree():
    root = CommentedMap()
    try:
        root_files_map = CommentedMap()
        for name in sorted(os.listdir(".")):
            if is_ignored(name):
                continue
            full_path = os.path.join(".", name)
            if os.path.isdir(full_path):
                subtree = build_tree(full_path, name)
                if not subtree:
                    empty = CommentedSeq()
                    empty.yaml_add_eol_comment("（省略）", 0)
                    root.yaml_set_comment_before_after_key(name, before="\n")
                    root[name] = empty
                else:
                    sorted_subtree = sort_entries(subtree)
                    root.yaml_set_comment_before_after_key(name, before="\n")
                    root[name] = sorted_subtree
            else:
                rel_path = name.replace("\\", "/")
                root_files_map[name] = rel_path
        if root_files_map:
            sorted_rf = CommentedSeq()
            for k in sorted(root_files_map):
                item = CommentedSeq([k, root_files_map[k]])
                item.fa.set_flow_style()
                sorted_rf.append(item)
            wrapper = CommentedMap()
            wrapper.yaml_set_comment_before_after_key("__files__", before="\n")
            wrapper["__files__"] = sorted_rf
            root.yaml_set_comment_before_after_key("root_files", before="\n")
            root["root_files"] = wrapper
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
