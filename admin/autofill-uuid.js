// autofill-uuid.js
window.addEventListener("DOMContentLoaded", () => {
  const articleIdField = document.getElementById("articleId");
  if (articleIdField && !articleIdField.value) {
  	  articleIdField.value = generateShortUUID();
//    articleIdField.value = generateUUID();
  }
});
