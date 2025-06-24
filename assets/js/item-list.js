document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('section[data-item-list]').forEach(section => {
    const suffix = section.dataset.taxonomyList;
    const filter = document.getElementById(`filter-${suffix}`);
    const sort = document.getElementById(`sort-${suffix}`);
    const list = section.querySelector('ul') || section;
    if (!filter || !sort || !list) return;

    const items = Array.from(list.children);
    
    function apply() {
      const term = filter.value.toLowerCase();
      let filtered = items.filter(li => li.textContent.toLowerCase().includes(term));
      switch (sort.value) {
        case 'name':
          filtered.sort((a, b) => a.textContent.localeCompare(b.textContent));
          break;
        case 'count':
          filtered.sort((a, b) => parseInt(b.dataset.count || '0') - parseInt(a.dataset.count || '0'));
          break;
        case 'priority':
          filtered.sort((a, b) => parseInt(a.dataset.priority || '0') - parseInt(b.dataset.priority || '0'));
          break;
        case 'title':
          filtered.sort((a, b) => (a.dataset.title || '').localeCompare(b.dataset.title || ''));
          break;
        case 'date':
          filtered.sort((a, b) => (b.dataset.date || '').localeCompare(a.dataset.date || ''));
          break;
      }
      list.innerHTML = '';
      filtered.forEach(li => list.appendChild(li));
    }

    filter.addEventListener('input', apply);
    sort.addEventListener('change', apply);
    apply();
  });
});
