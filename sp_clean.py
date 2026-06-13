import sys
sys.stdout.reconfigure(encoding='utf-8')
path = 'E:/CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets/pages/SocialPage.ets'
with open(path, 'r', encoding='utf-8-sig') as f:
    lines = f.readlines()

# Keep lines 0-25 (imports, struct declaration, aboutToAppear)
# Then lines 27-73 (loadPosts method)
# Then add loadCheckinStatus, doCheckin
# Then skip to getMockPosts and after

# Find the REAL getMockPosts (the good one, not the broken one)
# After line 73, there's the broken text. Let me find the real start of getMockPosts
# The first occurrence of 'getMockPosts()' after line 100 should be the real one

result = []
# Lines 0-25: good
result.extend(lines[0:26])  # imports, struct, aboutToAppear
# Lines 27-73: loadPosts + getMockPosts comment
result.extend(lines[27:74])

# Now add loadCheckinStatus and doCheckin
new_methods = '''  /**
   * 加载打卡状态
   */
  async loadCheckinStatus(): Promise<void> {
    try {
      this.isCheckedIn = await this.dbHelper.isCheckedInToday()
      this.consecutiveDays = await this.dbHelper.getConsecutiveCheckinDays()
    } catch (err) {
      console.error('SocialPage', '\u52a0\u8f7d\u6253\u5361\u72b6\u6001\u5931\u8d25')
    }
  }

  /**
   * 执行打卡签到
   */
  async doCheckin(): Promise<void> {
    try {
      const success = await this.dbHelper.doCheckin('', this.inputText)
      if (success) {
        this.isCheckedIn = true
        this.consecutiveDays = await this.dbHelper.getConsecutiveCheckinDays()
        promptAction.showToast({ message: '\u6253\u5361\u6210\u529f\uff01', duration: 1500 })
      }
    } catch (err) {
      promptAction.showToast({ message: '\u6253\u5361\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5', duration: 1500 })
    }
  }

'''
result.append(new_methods)

# Find real getMockPosts - look for it after line 140 (past the broken code)
real_start = None
for i in range(140, len(lines)):
    if "getMockPosts(): SocialPost[]" in lines[i]:
        real_start = i
        break

if real_start:
    print(f"Found real getMockPosts at line {real_start+1}")
    result.extend(lines[real_start:])
else:
    print("Could not find getMockPosts!")
    sys.exit(1)

# Write the cleaned file
out_path = 'E:/CodeProjects/HarmonyOSProjects/WebApp/poemstudy/poemstudyapp/entry/src/main/ets/pages/SocialPage.ets'
with open(out_path, 'w', encoding='utf-8') as f:
    f.writelines(result)
print(f'Written {len(result)} lines')
