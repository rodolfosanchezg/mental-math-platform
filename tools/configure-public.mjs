import { readFile, writeFile } from 'node:fs/promises';

// Whitelist only browser-safe values; never read administrative configuration.
const text = await readFile(new URL('../.env.supabase.public.local', import.meta.url), 'utf8');
const values = {};
for (const line of text.split(/\r?\n/)) {
  const match = line.match(/^\s*(?:export\s+)?(SUPABASE_URL|SUPABASE_PUBLISHABLE_KEY)\s*=\s*(.*?)\s*$/);
  if (match) values[match[1]] = match[2].replace(/^(['"])(.*)\1$/, '$2');
}
const url = new URL(values.SUPABASE_URL);
if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash
    || !/^sb_publishable_[A-Za-z0-9_-]+$/.test(values.SUPABASE_PUBLISHABLE_KEY ?? '')) {
  throw new Error('Invalid public Supabase configuration (values suppressed)');
}
await writeFile(new URL('../src/js/config.js', import.meta.url),
  `// Public browser configuration approved by D-020. No private credentials.\nexport const supabaseConfig = Object.freeze(${JSON.stringify({
    url: url.href.replace(/\/$/, ''), publishableKey: values.SUPABASE_PUBLISHABLE_KEY,
  }, null, 2)});\n`);
console.log('Public browser configuration generated; values suppressed');
