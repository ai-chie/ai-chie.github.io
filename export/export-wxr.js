async function exportToWXR(postUrl) {
  const response = await fetch(postUrl);
  const text = await response.text();
  const meta = {
    title: (text.match(/^title:\s*(.+)$/m) || [])[1] || "Untitled",
    date: (text.match(/^date:\s*(.+)$/m) || [])[1] || new Date().toISOString(),
  };
  const content = text.replace(/---[\s\S]+?---/, "").replace(/<[^>]+>/g, "");
  const wxr = \`
<rss version="2.0"
  xmlns:excerpt="http://wordpress.org/export/1.2/excerpt/"
  xmlns:content="http://purl.org/rss/1.0/modules/content/"
  xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>\${meta.title}</title>
    <pubDate>\${new Date(meta.date).toUTCString()}</pubDate>
    <item>
      <title>\${meta.title}</title>
      <pubDate>\${new Date(meta.date).toUTCString()}</pubDate>
      <content:encoded><![CDATA[\${content}]]></content:encoded>
    </item>
  </channel>
</rss>\`.trim();
  const blob = new Blob([wxr], { type: "application/rss+xml" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = \`\${meta.title}.wxr.xml\`;
  a.click();
}
