import sys
sys.stdout.reconfigure(encoding='utf-8')
path = 'E:/CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets/pages/SocialPage.ets'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()
print(f'Lines: {len(lines)}')
print(f'First: {repr(lines[0][:60])}')
print(f'Last: {repr(lines[-1][:60])}')
# Check for key items
checks = ['loadCheckinStatus', 'doCheckin', 'getMockPosts', 'onToggleLike', 'publish', 'headerBar', 'checkinBar']
for c in checks:
    found = any(c in l for l in lines)
    print(f'  {c}: {\"✓\" if found else \"✗\"} ')
# Check for issues
issues = ['\x27', '\\n', 'Record<string, Object>']
for c in issues:
    found = any(c in l for l in lines)
    print(f'  Issue[{repr(c)}]: {\"⚠\" if found else \"✓\"} ')
