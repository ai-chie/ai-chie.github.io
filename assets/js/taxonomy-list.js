document.addEventListener('DOMContentLoaded', () => {
  const filter = document.getElementById('filter');
  const sort = document.getElementById('sort');
  const list = document.querySelector('section ul');
  if (!filter || !sort || !list) return;

  const items = Array.from(list.children);

  function apply() {
    let term = filter.value.toLowerCase();
    let filtered = items.filter(li => li.textContent.toLowerCase().includes(term));
    if (sort.value === 'name') {
      filtered.sort((a, b) => a.textContent.localeCompare(b.textContent));
    } else {
      filtered.sort((a, b) => parseInt(b.dataset.count || '0') - parseInt(a.dataset.count || '0'));
    }
    list.innerHTML = '';
    filtered.forEach(li => list.appendChild(li));
  }

  filter.addEventListener('input', apply);
  sort.addEventListener('change', apply);
  apply();
});
