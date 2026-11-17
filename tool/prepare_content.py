"""Prepare local Adhkar data from pinned upstream snapshots; Python stdlib only.

Upstream dataset licensing is not declared. Fetching data does not grant rights
to redistribute it. See THIRD_PARTY_NOTICES.md before publishing an app.
"""
from argparse import ArgumentParser
from hashlib import sha256
from pathlib import Path
import json
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def json_digest(data):
    canonical = json.dumps(data, ensure_ascii=False, sort_keys=True,
                           separators=(",", ":")).encode("utf-8")
    return sha256(canonical).hexdigest()


def checked_json(data, expected, label):
    actual = json_digest(data)
    if actual != expected:
        raise ValueError(f"Checksum mismatch for {label}: refusing changed content")
    return data


def prepare(output_root, source_dir=None):
    manifest = json.loads((ROOT / "tool/content_manifest.json").read_text(encoding="utf-8"))
    sources = {}
    payloads = {}
    for name, spec in manifest["sources"].items():
        existing = (source_dir / name if source_dir else output_root / "design" / name)
        if existing.exists():
            raw = existing.read_bytes()
        elif source_dir:
            raise FileNotFoundError(existing)
        else:
            request = urllib.request.Request(spec["url"], headers={"User-Agent": "Rafeeq-content-setup/1.0"})
            with urllib.request.urlopen(request, timeout=25) as response:
                raw = response.read(8 * 1024 * 1024 + 1)
            if len(raw) > 8 * 1024 * 1024:
                raise ValueError("Unexpected source size")
        sources[name] = json.loads(raw.decode("utf-8-sig"))
        checked_json(sources[name], spec["json_sha256"], name)
        payloads[output_root / "design" / name] = raw

    rows = sources["adhkar-source.json"]["rows"]
    hisn = {f"hisn-{c['ID']}-{e['ID']}": e
            for c in sources["hisn-source.json"]["English"] for e in c["TEXT"]}
    entries = []
    for spec in manifest["selection"]:
        if spec["id"].startswith("azkar-db-"):
            row = rows[int(spec["id"].split("-")[-1]) - 1]
            entry = {"id": spec["id"], "category": spec["category"],
                     "text": row[1], "count": row[3], "reference": row[4],
                     "source": spec["source"]}
            if row[2] and row[2].strip():
                entry["virtue"] = row[2]
        else:
            row = hisn[spec["id"]]
            entry = {"id": spec["id"], "category": spec["category"],
                     "text": row["ARABIC_TEXT"], "count": row["REPEAT"],
                     "reference": spec["reference"], "source": spec["source"]}
        entries.append(entry)
    if len(entries) != 77 or len({e["id"] for e in entries}) != 77:
        raise ValueError("Unexpected Adhkar inventory")
    generated = (json.dumps(entries, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    checked_json(entries, manifest["generated_json_sha256"], "adhkar.json")
    payloads[output_root / "assets/data/adhkar.json"] = generated
    # Validate every input and result before touching any destination.
    for path, raw in payloads.items():
        if path.exists() and json.loads(path.read_text(encoding="utf-8-sig")) != json.loads(raw.decode("utf-8-sig")):
            raise ValueError(f"Refusing to overwrite a changed local file: {path}")
    for path, raw in payloads.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            path.write_bytes(raw)
    print(f"Prepared 77 dhikr entries and 26 source descriptions in {output_root}")


if __name__ == "__main__":
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", type=Path, default=ROOT)
    parser.add_argument("--source-dir", type=Path, help="Use verified local snapshots instead of downloading")
    args = parser.parse_args()
    prepare(args.output_root.resolve(), args.source_dir.resolve() if args.source_dir else None)
