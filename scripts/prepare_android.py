from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
android = root / "android"
if not (android / "gradlew").is_file():
    with tempfile.TemporaryDirectory() as directory:
        scaffold = Path(directory) / "academy"
        subprocess.run([
            "flutter", "create", "--platforms=android", "--org=com.lingora",
            "--project-name=academy", "--no-pub", str(scaffold),
        ], check=True)
        shutil.copytree(scaffold / "android", android, dirs_exist_ok=True)
    subprocess.run(["chmod", "+x", str(android / "gradlew")], check=True)
activity = android / "app/src/main/kotlin/com/lingora/academy/MainActivity.kt"
activity.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(root / "native/MainActivity.kt", activity)
manifest = android / "app/src/main/AndroidManifest.xml"
namespace = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", namespace)
attribute = lambda name: f"{{{namespace}}}{name}"
tree = ET.parse(manifest)
document = tree.getroot()
application = document.find("application")
application.set(attribute("label"), "LINGORA")
application.set(attribute("allowBackup"), "false")
if not any(node.get(attribute("name")) == "android.permission.INTERNET"
           for node in document.findall("uses-permission")):
    document.insert(0, ET.Element("uses-permission", {attribute("name"): "android.permission.INTERNET"}))
queries = document.find("queries")
if queries is None:
    queries = ET.SubElement(document, "queries")
for action in ("android.intent.action.TTS_SERVICE", "android.speech.action.RECOGNIZE_SPEECH"):
    if not any(node.get(attribute("name")) == action for node in queries.iter("action")):
        intent = ET.SubElement(queries, "intent")
        ET.SubElement(intent, "action", {attribute("name"): action})
tree.write(manifest, encoding="utf-8", xml_declaration=True)
for icon in (android / "app/src/main/res").glob("mipmap-*/ic_launcher.png"):
    subprocess.run(["python3", "-c",
        "from PIL import Image; import sys; p=Image.open(sys.argv[2]); w=p.size; "
        "p.close(); Image.open(sys.argv[1]).convert('RGBA').resize(w, Image.Resampling.LANCZOS).save(sys.argv[2])",
        str(root / "assets/lumi.jpg"), str(icon)], check=True)
