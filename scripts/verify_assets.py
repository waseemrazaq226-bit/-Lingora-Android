"""Check packaged curriculum references, audio and the catalog without Flutter."""
from pathlib import Path
import json
import re
import subprocess

root = Path(__file__).resolve().parents[1]
worlds = json.loads((root / "assets/english_urdu.json").read_text())
assert len(worlds) == 5
ids, phrases, paths = set(), set(), set()
for world in worlds:
    assert len(world["lessons"]) == 3
    for lesson in world["lessons"]:
        assert lesson["id"] not in ids
        ids.add(lesson["id"])
        assert len(lesson["entries"]) == 3
        for index, phrase in enumerate(lesson["entries"]):
            assert set(phrase) == {"en", "ur", "tip", "urduTip"}
            assert all(value.strip() for value in phrase.values())
            assert re.search(r"[\u0600-\u06ff]", phrase["urduTip"])
            assert re.search(r"[\u0600-\u06ff]", phrase["ur"])
            assert phrase["en"] not in phrases
            phrases.add(phrase["en"])
            audio = root / "assets/audio" / f'{lesson["id"]}_{index}.mp3'
            paths.add(audio)
            subprocess.run(["ffmpeg", "-v", "error", "-xerror", "-i", str(audio),
                            "-f", "null", "-"], check=True)
assert paths == set((root / "assets/audio").glob("*.mp3"))
catalog = (root / "lib/catalog.dart").read_text()
codes = re.findall(r"Language\('([^']+)'", catalog)
assert len(codes) == len(set(codes)) == 59
assert 'code == \'en\'' in catalog
print(f"Verified {len(worlds)} worlds, {len(ids)} lessons, {len(phrases)} bilingual entries, "
      f"{len(paths)} decodable audio files and {len(codes)} language codes.")
