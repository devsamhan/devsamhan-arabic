const fs = require('fs');
const path = require('path');

const [distPath, corpusPath, outPath] = process.argv.slice(2);
if (!distPath || !corpusPath || !outPath) {
  console.error('usage: node tools/parity/run_javascript.cjs <dist-index.js> <corpus.json> <out.json>');
  process.exit(2);
}
const api = require(path.resolve(distPath));
const corpus = JSON.parse(fs.readFileSync(corpusPath, 'utf8'));

const ops = {
  toSearchKey: api.toSearchKey,
  toLooseSearchKey: api.toLooseSearchKey,
  normalizeName: api.normalizeName,
  toDisplayKey: api.toDisplayKey,
  toSlug: api.toSlug,
  removeTashkeel: api.removeTashkeel,
  removeTatweel: api.removeTatweel,
  normalizeAlef: api.normalizeAlef,
  normalizeHamza: api.normalizeHamza,
  normalizeYa: api.normalizeYa,
  normalizeTaMarbouta: api.normalizeTaMarbouta,
  normalizePresentationForms: api.normalizePresentationForms,
  digitsWestern: (s) => api.normalizeDigits(s, 'western'),
  digitsEastern: (s) => api.normalizeDigits(s, 'eastern'),
};

const cps = (value) =>
  Array.from(value)
    .map((c) => 'U+' + c.codePointAt(0).toString(16).toUpperCase().padStart(4, '0'))
    .join(' ');

const rows = [];
for (const item of corpus.inputs) {
  for (const name of corpus.operations) {
    const output = ops[name](item.text);
    rows.push({
      id: item.id,
      operation: name,
      input: item.text,
      output,
      codepoints: cps(output),
    });
  }
}
fs.writeFileSync(
  outPath,
  JSON.stringify({ impl: 'typescript', seed: corpus.seed, results: rows }, null, 1),
  'utf8'
);
console.log('TS_RESULTS', rows.length);
