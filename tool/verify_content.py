"""Verify shipped content against the downloaded, unmodified source snapshots."""
from pathlib import Path
import hashlib
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
quran = json.loads((ROOT / 'assets/data/quran.json').read_text(encoding='utf8'))
source = ET.fromstring((ROOT / 'design/tanzil-uthmani.xml').read_bytes())
assert len(source) == len(quran['surahs']) == 114
assert sum(len(s) for s in source) == 6236
for actual, expected in zip(quran['surahs'], source):
    assert actual['id'] == int(expected.attrib['index'])
    assert actual['name'] == expected.attrib['name']
    assert actual['basmala'] == expected[0].attrib.get('bismillah')
    assert actual['verses'] == [a.attrib['text'] for a in expected]
assert 'CHANGING IT IS NOT ALLOWED' in quran['notice']

original = json.loads((ROOT / 'design/adhkar-source.json').read_text(encoding='utf8'))['rows']
hisn = json.loads((ROOT / 'design/hisn-source.json').read_text(encoding='utf-8-sig'))['English']
hisn_by_id = {f"hisn-{c['ID']}-{e['ID']}": e for c in hisn for e in c['TEXT']}
entries = json.loads((ROOT / 'assets/data/adhkar.json').read_text(encoding='utf8'))
assert len(entries) == len({e['id'] for e in entries}) == 77
assert len({e['category'] for e in entries}) == 6
for entry in entries:
    if entry['id'].startswith('azkar-db-'):
        row = original[int(entry['id'].split('-')[-1]) - 1]
        assert (entry['text'], entry['count'], entry['reference']) == (row[1], row[3], row[4])
        assert entry.get('virtue') == (row[2] if row[2] and row[2].strip() else None)
    else:
        row = hisn_by_id[entry['id']]
        assert (entry['text'], entry['count']) == (row['ARABIC_TEXT'], row['REPEAT'])
for name in ['quran.json', 'adhkar.json']:
    path = ROOT / 'assets/data' / name
    print(name, 'SHA256', hashlib.sha256(path.read_bytes()).hexdigest())
print('Verified: 6236 Quran verses, 114 surahs, 77 dhikr entries, six categories.')

metadata = ET.parse(ROOT / 'design/quran-metadata.xml').getroot()
pages = json.loads((ROOT / 'assets/data/quran-pages.json').read_text(encoding='utf8'))['pages']
assert len(pages) == len(metadata.find('pages')) == 604
for actual, expected in zip(pages, metadata.find('pages')):
    assert actual == {'page': int(expected.attrib['index']), 'surah': int(expected.attrib['sura']), 'verse': int(expected.attrib['aya'])}
print('Verified all 604 page starts against official Tanzil Medina Mushaf metadata.')
