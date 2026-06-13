import sys
path = 'E:/CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets/pages/QuizPage.ets'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()
# Replace String.fromCharCode with safer alternative
old = "Text(String.fromCharCode(65 + optIndex)) // A, B, C, D"
new = "Text(['A', 'B', 'C', 'D', 'E', 'F'][optIndex] ?? '?')"
content = content.replace(old, new)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed String.fromCharCode in QuizPage')
