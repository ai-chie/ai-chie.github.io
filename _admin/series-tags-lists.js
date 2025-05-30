async function loadTagsAndSeries() {
  // タグの読み込み
  const tagRes = await fetch('../_data/_generated/tags.json');
  const tags = await tagRes.json();
  const tagSelect = document.getElementById('tags');
  tags.forEach(tag => {
    const opt = document.createElement('option');
    opt.value = tag.name;
    opt.textContent = tag.name;
    tagSelect.appendChild(opt);
  });

  // シリーズの読み込み
  const seriesRes = await fetch('../_data/_generated/series.json');
  const seriesList = await seriesRes.json();
  const seriesSelect = document.getElementById('series');
  seriesList.forEach(series => {
    const opt = document.createElement('option');
    opt.value = series.id;
    opt.textContent = series.title;
    seriesSelect.appendChild(opt);
  });
}

// フォーム初期化時に呼び出し
document.addEventListener('DOMContentLoaded', () => {
  loadTagsAndSeries();
});
