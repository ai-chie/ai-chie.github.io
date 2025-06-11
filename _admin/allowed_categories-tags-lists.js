async function loadTagsAndCategories() {
  // タグの読み込み
  const tagsRes = await fetch('../_data/_generated/initial_tags_list.json');
  const tagsList = await tagsRes.json();
  const tagsSelect = document.getElementById('tags');
  tagsList.forEach(tag => {
    const opt = document.createElement('option');
    opt.value = tag.name;
    opt.textContent = tag.name;
    tagsSelect.appendChild(opt);
  });

  // カテゴリの読み込み
  const categoriesRes = await fetch('../_data/_generated/initial_categories_list.json');
  const categoriesList = await categoriesRes.json();
  const categoriesSelect = document.getElementById('categories');
  categoriesList.forEach(categories => {
    const opt = document.createElement('option');
    opt.value = categories.id;
    opt.textContent = categories.title;
    categoriesSelect.appendChild(opt);
  });
}

// フォーム初期化時に呼び出し
document.addEventListener('DOMContentLoaded', () => {
  loadTagsAndCategories();
});
