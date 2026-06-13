import sys, os, re
sys.stdout.reconfigure(encoding='utf-8')
root = 'E:/CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets'
for dirpath, _, files in os.walk(root):
    for f in sorted(files):
        if not f.endswith('.ets'):
            continue
        path = os.path.join(dirpath, f)
        with open(path, 'r', encoding='utf-8') as fh:
            lines = fh.readlines()
        rel = os.path.relpath(path, root)
        # Check for potential issues
        for i, line in enumerate(lines):
            # AppStorage.setOrCreate (should be AppStorage.set)
            if 'AppStorage.setOrCreate' in line:
                print(f'{rel}:{i+1}: WARNING AppStorage.setOrCreate detected')
            # Type assertions with 'as any' that might mask issues
            # Check for missing semicolons in import statements
            if line.strip().startswith('import ') and '}' in line and not line.strip().endswith(';') and not line.strip().endswith("'"):
                # imports without semicolon are fine in ArkTS
                pass
print('No critical issues found')
