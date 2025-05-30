// autofill-date.js
window.addEventListener('DOMContentLoaded', () => {
    const postDateField = document.getElementById('postDate');
    if (!postDateField) return;

    const now = new Date();
    const pad = n => n.toString().padStart(2, '0');

    const formattedDate = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}T${pad(now.getHours())}:${pad(now.getMinutes())}`;
    postDateField.value = formattedDate;
});
