import sys
sys.stdout.reconfigure(encoding="utf-8")
path = "E:/CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets/pages/SocialPage.ets"
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()
print(f"Total lines: {len(lines)}")
for i in range(0, min(30, len(lines))):
    print(f"{i+1}: {repr(lines[i][:100])}")
