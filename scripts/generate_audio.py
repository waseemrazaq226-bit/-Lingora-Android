"""Rebuild the bundled practice audio with an FFmpeg build that includes Flite."""
from pathlib import Path
import json
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
worlds = json.loads((root / "assets/english_urdu.json").read_text())
audio = root / "assets/audio"
audio.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory() as folder:
    text = Path(folder) / "phrase.txt"
    for world in worlds:
        for lesson in world["lessons"]:
            for index, phrase in enumerate(lesson["entries"]):
                text.write_text(phrase["en"], encoding="utf-8")
                output = audio / f'{lesson["id"]}_{index}.mp3'
                subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "lavfi",
                                "-i", f"flite=textfile={text}:voice=slt",
                                "-codec:a", "libmp3lame", "-b:a", "48k", str(output)],
                               check=True)
