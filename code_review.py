import os, re

ets_dir = "E:/CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets"

# Scan all .ets files and look for common issues
issues = []
all_files = []

for root, dirs, files in os.walk(ets_dir):
    for f in files:
        if f.endswith(".ets"):
            all_files.append(os.path.join(root, f))

print(f"Total .ets files found: {len(all_files)}")

# Check each file for potential issues
for fp in all_files:
    rel = os.path.relpath(fp, ets_dir)
    with open(fp, "r", encoding="utf-8") as fh:
        try:
            content = fh.read()
        except:
            issues.append(f"  FAIL to read: {rel}")
            continue
    
    lines = content.split("\n")
    
    # Check for common issues
    for i, line in enumerate(lines, 1):
        # Unused imports (coarse check)
        if re.search(r"import\s+\{.*?\}\s+from", line):
            # Check if any imported symbols are used in the file
            imports = re.findall(r"import\s+\{(.*?)\}\s+from", line)
            if imports:
                symbols = [s.strip() for s in imports[0].split(",")]
                for sym in symbols:
                    if sym and sym not in content.replace(line, ""):
                        pass  # too noisy, skip for now
        
        # Hardcoded colors (not using $r)
        if re.search(r"fontColor\('#[0-9A-Fa-f]{6}'\)", line) or re.search(r"backgroundColor\('#[0-9A-Fa-f]{6}'\)", line):
            color = re.search(r"#([0-9A-Fa-f]{6})", line)
            if color and color.group(1) not in ["FFFFFF", "F5F5F5", "333333", "999999", "CCCCCC", "666666"]:
                pass  # common colors, skip for now
        
        # Check for template literal with ${} that might have encoding issues
        if "`%" in line and "${keyword}%`" not in line and "${" in line:
            m = re.search(r"`[^`]*\$\{[^}]*\}[^`]*`", line)
            if m:
                # Check it's valid
                pass

print(f"\nScanned {len(all_files)} files")
print("Detailed analysis below...")