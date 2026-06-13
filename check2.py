import sys
sys.stdout.reconfigure(encoding="utf-8")
path = "E:/CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets/pages/SocialPage.ets"
with open(path, "r", encoding="utf-8-sig") as f:
    lines = f.readlines()
print(f"Total lines: {len(lines)}")
for i in range(len(lines)):
    if i < 10 or "loadCheckinStatus" in repr(lines[i]).lower() or "doCheckin" in repr(lines[i]).lower() or "getMockPosts" in repr(lines[i]):
        print(f"{i+1}: {repr(lines[i][:120])}")
