fetch('/admin/config.yml')
  .then(res => res.text())
  .then(text => {
    const config = jsyaml.load(text);
    window.CMS.init({ config });
  });
