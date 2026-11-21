import pathlib, re, sys

sys.stdout.reconfigure(encoding='utf-8', errors='backslashreplace')
root = pathlib.Path(sys.argv[1])
# sequencias classicas de UTF-8 lido como CP1252
suspects = ['Ã¡', 'Ã£', 'Ã©', 'Ã³', 'Ã§', 'Ã­', 'Ãº', 'Ãµ', 'Ã¤', 'Ã¶', 'â€', 'Â¡', 'Â²', 'Ã¦']
problems = 0
for p in sorted(root.rglob('*')):
    if not p.is_file():
        continue
    rel = str(p.relative_to(root))
    data = p.read_bytes()
    try:
        text = data.decode('utf-8')
    except UnicodeDecodeError as e:
        print('ENCODING-ERR', rel, e)
        problems += 1
        continue
    if data[:3] == b'\xef\xbb\xbf':
        print('BOM', rel)
    lines = text.splitlines()
    for i, l in enumerate(lines, 1):
        hit = next((s for s in suspects if s in l), None)
        if hit:
            print('MOJIBAKE?', rel, i, hit, repr(l[:70]))
            problems += 1
    if lines and not lines[-1].strip():
        print('EMPTY-LAST-LINE (ok, apenas informativo)', rel)
print('arquivos:', sum(1 for p in root.rglob('*') if p.is_file()))
sk = (root / 'SKILL.md').read_text(encoding='utf-8')
print('linhas SKILL.md:', len(sk.splitlines()))
print('frontmatter name:', re.search(r'^name:\s*(.+)$', sk, re.M).group(1))
print('descricao chars:', len(re.search(r'^description:\s*(.+)$', sk, re.M).group(1)))
print('problemas:', problems)
