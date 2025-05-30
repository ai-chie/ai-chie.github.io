// convert-yaml-to-json.js
const fs = require('fs');
const yaml = require('js-yaml');
const path = require('path');

const inputDir = path.join(__dirname, '_data');
const outputDir = path.join(__dirname, '_data/_generated');

// 出力先フォルダが存在しなければ作成
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

fs.readdirSync(inputDir).forEach(file => {
  if (file.endsWith('.yml') || file.endsWith('.yaml')) {
    const yamlPath = path.join(inputDir, file);
    const jsonPath = path.join(outputDir, file.replace(/\.ya?ml$/, '.json'));

    try {
      const data = yaml.load(fs.readFileSync(yamlPath, 'utf8'));
      fs.writeFileSync(jsonPath, JSON.stringify(data, null, 2), 'utf8');
      console.log(`✅ Converted: ${file} → ${path.relative(__dirname, jsonPath)}`);
    } catch (err) {
      console.error(`❌ Error converting ${file}:`, err.message);
    }
  }
});

/*if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir);
const files = fs.readdirSync(inputDir).filter(file => file.endsWith('.yml'));

files.forEach(file => {
  const yamlPath = path.join(inputDir, file);
  const jsonPath = path.join(outputDir, file.replace('.yml', '.json'));
  const content = fs.readFileSync(yamlPath, 'utf8');
  const data = yaml.load(content);
  fs.writeFileSync(jsonPath, JSON.stringify(data, null, 2), 'utf8');
  console.log(`✅ Converted: ${file} → ${path.basename(jsonPath)}`);
});*/
