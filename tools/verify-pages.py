"""Verify the src-only Pages artifact without printing configuration values."""
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1] / 'src'


def require(condition, message):
    if not condition:
        raise SystemExit(message)


private = re.compile(
    r'sb_secret_[A-Za-z0-9_-]+|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
    r'|postgres(?:ql)?://[^\s:/]+:[^\s@]+@'
    r'|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
    r'|PGPASSWORD|SUPABASE_SECRET_KEY|service_role'
)
files = []
for path in root.rglob('*'):
    require(not path.is_symlink(), 'Publication rejected: symlink in src')
    require(not path.name.startswith('.env') and path.suffix.lower() not in
            {'.pem', '.key', '.p12', '.pfx', '.dump', '.backup'}, 'Publication rejected: sensitive file in src')
    if not path.is_file():
        continue
    require(path.name not in {'credentials.json', '.pgpass', '.pg_service.conf'}, 'Publication rejected: credentials in src')
    require(not private.search(path.read_bytes().decode('utf8', errors='replace')),
            'Publication rejected: private credential signature in src (values suppressed)')
    if path.name != '.gitkeep':
        files.append(path)


def relative_reference(source, reference):
    require(reference.startswith('./') or reference.startswith('../'), 'Publication rejected: non-relative app reference')
    target = (source.parent / reference).resolve()
    require(target.is_relative_to(root) and target.is_file(), 'Publication rejected: missing or external static reference')


index = root / 'index.html'
require(index.is_file(), 'Publication rejected: index.html missing')
for reference in re.findall(r'(?:src|href)="([^"]+)"', index.read_text()):
    relative_reference(index, reference)
for source in root.rglob('*.js'):
    for reference in re.findall(r'(?:from\s+|import\s*)[\'"]([^\'"]+)[\'"]', source.read_text()):
        relative_reference(source, reference)

config_text = (root / 'js/config.js').read_text()
match = re.search(r'Object\.freeze\((\{.*?\})\)', config_text, re.S)
require(match is not None, 'Publication rejected: invalid public configuration')
config = json.loads(match[1])
require(set(config) == {'url', 'publishableKey'} and config['url'].startswith('https://')
        and re.fullmatch(r'sb_publishable_[A-Za-z0-9_-]+', config['publishableKey']),
        'Publication rejected: public-only Supabase configuration required')
print(f'PASS: src/index.html, relative app references, {len(files)} static files, public-only Supabase configuration')
