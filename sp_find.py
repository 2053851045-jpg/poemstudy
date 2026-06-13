import sys
sys.stdout.reconfigure(encoding='utf-8')
path = 'E:/CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets/pages/SocialPage.ets'
with open(path, 'r', encoding='utf-8-sig') as f:
    lines = f.readlines()
for i in range(len(lines)):
    if 'getMockPosts' in lines[i]:
        print(f'{i+1}: {repr(lines[i][:120])}')
print('---')
# Also show a few lines around line 260-301
for i in range(260, min(len(lines), 301)):
    print(f'{i+1}: {repr(lines[i][:120])}')
