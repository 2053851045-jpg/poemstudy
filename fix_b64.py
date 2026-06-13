import sys
path = 'E:/\CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets/pages/SocialPage.ets'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace('\\n', '\n')
open(path, 'w', encoding='utf-8').write(c)
print('Done')