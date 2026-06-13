import sys
path = 'E:/CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets/common/Constants.ets'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()
# Fix duplicate KEY_USER_ID
old = "export const KEY_USER_ID = 'userId'\nexport const KEY_USER_ID = 'userId'"
new = "export const KEY_USER_ID = 'userId'"
content = content.replace(old, new)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed duplicate KEY_USER_ID')
