import { DatabaseHelper } from '../model/DatabaseHelper'
import { Poem } from '../common/Types'
import { router } from '@kit.ArkUI'
import { QuizStatus } from '../common/Enums'
import { QUIZ_QUESTION_COUNT, QUIZ_TIME_LIMIT } from '../common/Constants'

// 题目数据结构
interface QuizQuestion {
  poem: Poem
  question: string     // 题干（上句）
  answer: string       // 正确答案（下句）
  options: string[]    // 4 个选项（含正确答案，已打乱）
  userAnswer: number   // 用户选择的索引，-1 表示未作答
}

/**
 * 测验结果自定义弹窗（@CustomDialog）
 */
@CustomDialog
export struct QuizResultDialog {
  controller: CustomDialogController
  score: number = 0
  total: number = 5
  onRetry: () => void = () => {}
  onViewRecords: () => void = () => {}
  onClose: () => void = () => {}

  build() {
    Column() {
      // 分数图标
      Text(this.score >= 4 ? '🎉' : (this.score >= 2 ? '👍' : '💪'))
        .fontSize(56)
        .margin({ top: 28 })

      Blank().height(8)

      Text('测验完成')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Blank().height(12)

      // 分数展示
      Row() {
        Text(this.score.toString())
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A90D9')
        Text(' / ' + this.total.toString())
          .fontSize(24)
          .fontColor('#999999')
      }

      Blank().height(4)

      Text(this.getScoreMsg())
        .fontSize(14)
        .fontColor('#666666')

      Blank().height(24)

      Divider().strokeWidth(0.5).color('#EEEEEE').margin({ left: 24, right: 24 })

      Blank().height(16)

      // 统计信息
      Row() {
        this.statItem('总题数', this.total.toString())
        this.statItem('答对', this.score.toString())
        this.statItem('正确率', Math.round((this.score / this.total) * 100).toString() + '%')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ left: 20, right: 20 })

      Blank().height(24)

      // 操作按钮
      Row() {
        Button('再来一局')
          .fontSize(15)
          .fontColor('#4A90D9')
          .backgroundColor('#EDF4FF')
          .borderRadius(22)
          .height(44)
          .layoutWeight(1)
          .onClick(() => {
            this.controller.close()
            if (this.onRetry) this.onRetry()
          })

        Blank().width(16)

        Button('查看记录')
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor('#4A90D9')
          .borderRadius(22)
          .height(44)
          .layoutWeight(1)
          .onClick(() => {
            this.controller.close()
            if (this.onViewRecords) this.onViewRecords()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })

      Blank().height(12)

      // 关闭按钮（退出弹窗，回到开始界面）
      Button('关闭')
        .fontSize(14)
        .fontColor('#999999')
        .backgroundColor(Color.Transparent)
        .borderRadius(20)
        .height(40)
        .width('100%')
        .onClick(() => {
          this.controller.close()
          if (this.onClose) this.onClose()
        })
    }
    .width('100%')
    .padding({ top: 24, bottom: 24 })
  }

  @Builder
  statItem(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 2 })
    }
  }

  getScoreMsg(): string {
    const rate = this.score / this.total
    if (rate === 1) return '太厉害了，全部答对！'
    if (rate >= 0.8) return '非常棒，继续保持！'
    if (rate >= 0.6) return '不错哦，再接再厉！'
    if (rate >= 0.4) return '还需努力，多读诗词~'
    return '加油，多学几首诗词吧！'
  }
}


@Component
export struct QuizPage {
  @State questions: QuizQuestion[] = []
  @State currentIndex: number = 0
  @State status: QuizStatus = QuizStatus.NOT_STARTED
  @State timeLeft: number = QUIZ_TIME_LIMIT
  @State timerStarted: boolean = false
  @State score: number = 0
  @State showResult: boolean = false
  @State isLoading: boolean = false
  @State selectedOption: number = -1
  @State isAnswered: boolean = false
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()
  private timerInterval: number | null = null
  private resultDialogController: CustomDialogController | null = null

  aboutToAppear(): void {
    // 不自动开始测验 — 显示开始界面，等用户点击「开始测试」
    // 如果之前是答题中（从其他 tab 切回来），恢复计时
    if (this.status === QuizStatus.ANSWERING && this.questions.length > 0) {
      this.resumeTimer()
    } else if (this.status !== QuizStatus.ANSWERING) {
      this.resetToStartScreen()
    }
  }

  aboutToDisappear(): void {
    this.stopTimer()
    // 关闭结果弹窗
    if (this.resultDialogController) {
      try {
        this.resultDialogController.close()
      } catch (e) {
        // ignore
      }
      this.resultDialogController = null
    }
  }

  /**
   * 重置为开始界面（保留 NOT_STARTED 状态）
   */
  resetToStartScreen(): void {
    this.stopTimer()
    this.status = QuizStatus.NOT_STARTED
    this.showResult = false
    this.isAnswered = false
    this.selectedOption = -1
    this.questions = []
    this.currentIndex = 0
    this.score = 0
    this.timeLeft = QUIZ_TIME_LIMIT
    this.isLoading = false
    if (this.resultDialogController) {
      this.resultDialogController = null
    }
  }

  /**
   * 用户点击「开始测试」按钮
   */
  startQuiz(): void {
    this.loadQuestions()
  }

  async loadQuestions(): Promise<void> {
    this.isLoading = true
    // 加载前先清空旧数据，防止 UI 闪现旧题
    this.questions = []
    this.currentIndex = 0
    this.score = 0
    this.selectedOption = -1
    this.isAnswered = false
    try {
      const poems = await this.dbHelper.getRandomPoems(QUIZ_QUESTION_COUNT)
      if (poems.length < 2) {
        this.status = QuizStatus.NOT_STARTED
        this.isLoading = false
        return
      }

      // 获取干扰选项用（额外随机抽一些诗词的句子）
      const extraPoems = poems.length < 10
        ? await this.dbHelper.getRandomPoems(10)
        : []

      this.questions = poems.map((poem, index) => {
        return this.generateQuestion(poem, index, poems, extraPoems)
      })

      this.currentIndex = 0
      this.score = 0
      this.status = QuizStatus.ANSWERING
      this.startTimer()
    } catch (err) {
      console.error('QuizPage', '加载题目失败')
      this.status = QuizStatus.NOT_STARTED
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 根据诗词生成一道填空题
   * 取诗词第一句作为题干，第二句作为答案
   */
  generateQuestion(poem: Poem, index: number, allPoems: Poem[], extraPoems: Poem[]): QuizQuestion {
    const lines = poem.content.split(/[，。！？,\.!\?\n]/).filter(s => s.trim().length > 0)

    let questionLine = lines[0] || poem.content.substring(0, 4)
    let answerLine = lines.length > 1 ? lines[1] : poem.content.substring(4, 8)

    // 确保题目和答案不重复（处理只有两行的诗词）
    if (questionLine === answerLine && lines.length > 2) {
      answerLine = lines[2]
    }

    // 收集错误选项
    const wrongOptions: string[] = []
    const allSentences: string[] = []

    // 从其他诗词中收集句子作为干扰项
    for (const p of allPoems) {
      if (p.id !== poem.id) {
        const pLines = p.content.split(/[，。！？,\.!\?\n]/).filter(s => s.trim().length > 1)
        for (const l of pLines) {
          if (l !== answerLine && !allSentences.includes(l)) {
            allSentences.push(l)
          }
        }
      }
    }

    // 从额外诗词中收集
    for (const p of extraPoems) {
      const pLines = p.content.split(/[，。！？,\.!\?\n]/).filter(s => s.trim().length > 1)
      for (const l of pLines) {
        if (l !== answerLine && !allSentences.includes(l)) {
          allSentences.push(l)
        }
      }
    }

    // 随机选取 3 个错误选项
    const shuffled = allSentences.sort(() => Math.random() - 0.5)
    const sliced = shuffled.slice(0, 3)
    for (let i = 0; i < sliced.length; i++) {
      wrongOptions.push(sliced[i])
    }

    // 如果干扰项不足 3 个，补占位
    while (wrongOptions.length < 3) {
      wrongOptions.push(`选项 ${wrongOptions.length + 1}`)
    }

    // 正确答案 + 错误选项 合并后随机打乱
    const options = [answerLine]
    for (let i = 0; i < wrongOptions.length; i++) {
      options.push(wrongOptions[i])
    }
    options.sort(() => Math.random() - 0.5)
    const correctIndex = options.indexOf(answerLine)

    return {
      poem: poem,
      question: questionLine,
      answer: answerLine,
      options: options,
      userAnswer: -1
    }
  }

  startTimer(): void {
    this.stopTimer()
    this.timeLeft = QUIZ_TIME_LIMIT
    this.timerStarted = true
    this.timerInterval = setInterval(() => {
      this.timeLeft--
      if (this.timeLeft <= 0) {
        this.stopTimer()
        this.finishQuiz()
      }
    }, 1000)
  }

  /**
   * 恢复计时（从其他 tab 切回时）
   */
  resumeTimer(): void {
    if (this.timerInterval !== null) return  // 已在计时
    this.timerStarted = true
    this.timerInterval = setInterval(() => {
      this.timeLeft--
      if (this.timeLeft <= 0) {
        this.stopTimer()
        this.finishQuiz()
      }
    }, 1000)
  }

  stopTimer(): void {
    this.timerStarted = false
    if (this.timerInterval !== null) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
  }

  onSelectOption(optionIndex: number): void {
    if (this.isAnswered) return

    this.isAnswered = true
    this.selectedOption = optionIndex

    const question = this.questions[this.currentIndex]
    const correctIndex = question.options.indexOf(question.answer)

    if (optionIndex === correctIndex) {
      this.score++
    }

    question.userAnswer = optionIndex

    // 延迟 800ms 后自动跳到下一题
    setTimeout(() => {
      if (this.currentIndex < this.questions.length - 1) {
        this.currentIndex++
        this.selectedOption = -1
        this.isAnswered = false
      } else {
        this.finishQuiz()
      }
    }, 800)
  }

  finishQuiz(): void {
    this.stopTimer()
    this.status = QuizStatus.COMPLETED
    this.showResult = true
    this.saveQuizRecord()
    // 打开 CustomDialog
    this.resultDialogController = new CustomDialogController({
      builder: QuizResultDialog({
        score: this.score,
        total: this.questions.length,
        onRetry: () => { this.onRetry() },
        onViewRecords: () => { this.onViewRecords() },
        onClose: () => { this.resetToStartScreen() }
      }),
      autoCancel: false,
      alignment: DialogAlignment.Center
    })
    this.resultDialogController.open()
  }

  async saveQuizRecord(): Promise<void> {
    try {
      const lastPoem = this.questions.length > 0 ? this.questions[this.questions.length - 1].poem : null
      const poemId: number = lastPoem ? lastPoem.id : 0
      await this.dbHelper.addQuizRecord(poemId, this.score)
    } catch (err) {
      console.error('QuizPage', '保存测验记录失败')
    }
  }

  onRetry(): void {
    // 先重置状态再加载新题
    this.resetToStartScreen()
    this.loadQuestions()
  }

  onViewRecords(): void {
    this.resetToStartScreen()
    router.pushUrl({ url: 'pages/QuizHistoryPage' })
  }

  getProgress(): number {
    if (this.questions.length === 0) return 0
    return ((this.currentIndex + (this.isAnswered ? 1 : 0)) / this.questions.length) * 100
  }

  getTimerPercent(): number {
    return (this.timeLeft / QUIZ_TIME_LIMIT) * 100
  }

  formatTime(): string {
    const min = Math.floor(this.timeLeft / 60)
    const sec = this.timeLeft % 60
    return `${min}:${sec.toString().padStart(2, '0')}`
  }

  build() {
    Column() {
      if (this.isLoading) {
        // 加载中
        Column() {
          LoadingProgress().width(32).height(32).color('#4A90D9')
          Blank().height(12)
          Text('加载题目中...').fontSize(14).fontColor('#999999')
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.status === QuizStatus.NOT_STARTED || this.questions.length === 0) {
        // 开始界面 / 数据不足
        if (this.status === QuizStatus.NOT_STARTED && !this.showResult) {
          this.startScreen()
        } else {
          this.emptyState()
        }
      } else if (this.status === QuizStatus.ANSWERING) {
        // 答题中
        this.quizContent()
      } else if (this.status === QuizStatus.COMPLETED) {
        // 已完成（弹窗由 CustomDialog 展示，这里显示底层内容防止空白）
        if (this.questions.length > 0) {
          this.quizContent()
        } else {
          this.startScreen()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 开始界面 — 用户主动点击「开始测试」才加载题目
   */
  @Builder
  startScreen() {
    Column() {
      Text('📝')
        .fontSize(64)
        .margin({ bottom: 16 })

      Text('诗词填空测验')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      Text('根据上句，选出正确的下句')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ bottom: 24 })

      // 规则说明卡片
      Column() {
        Row() {
          Text('📋').fontSize(16)
          Blank().width(8)
          Text('共 5 题，每题 4 个选项')
            .fontSize(14).fontColor('#666666')
        }
        .margin({ bottom: 8 })

        Row() {
          Text('⏱️').fontSize(16)
          Blank().width(8)
          Text('限时 60 秒，超时自动交卷')
            .fontSize(14).fontColor('#666666')
        }
        .margin({ bottom: 8 })

        Row() {
          Text('✅').fontSize(16)
          Blank().width(8)
          Text('选择后自动跳转下一题')
            .fontSize(14).fontColor('#666666')
        }
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ left: 32, right: 32, bottom: 32 })

      Button('开始测试')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor('#4A90D9')
        .borderRadius(24)
        .height(48)
        .width('60%')
        .onClick(() => {
          this.startQuiz()
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 20, right: 20 })
  }

  /**
   * 数据不足提示（题目数 < 2）
   */
  @Builder
  emptyState() {
    Column() {
      Text('✏️').fontSize(48)
      Blank().height(12)
      Text('题库数据不足，请先导入诗词数据').fontSize(14).fontColor('#999999')
      Blank().height(20)
      Button('重试')
        .fontSize(14)
        .fontColor('#4A90D9')
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#4A90D9' })
        .borderRadius(20)
        .padding({ left: 24, right: 24 })
        .onClick(() => { this.loadQuestions() })
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  @Builder
  quizContent() {
    Column() {
      // 顶部：进度条 + 计时器
      this.quizHeader()

      // 题目卡片
      Column() {
        // 题干
        Column() {
          Text(`第 ${this.currentIndex + 1} / ${this.questions.length} 题`)
            .fontSize(13)
            .fontColor('#999999')
            .margin({ bottom: 16 })

          Text('请选择「')
            .fontSize(15)
            .fontColor('#333333')
          Text(this.questions[this.currentIndex].question)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .margin({ top: 4, bottom: 4 })
          Text('」的下一句')
            .fontSize(15)
            .fontColor('#333333')
        }
        .width('100%')
        .padding(20)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 16, right: 16, top: 24 })
      }

      // 选项
      Column() {
        ForEach(this.questions[this.currentIndex].options, (option: string, optIndex: number) => {
          this.optionButton(option, optIndex)
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 20 })
    }
    .width('100%')
  }

  @Builder
  optionButton(option: string, optIndex: number) {
    Row() {
      // 序号圆点
      Text(['A', 'B', 'C', 'D', 'E', 'F'][optIndex] ?? '?')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getOptionTextColor(optIndex))
        .width(28).height(28)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getOptionBgColor(optIndex))
        .borderRadius(14)
        .border({ width: 1, color: this.getOptionBorderColor(optIndex) })

      Blank().width(12)

      Text(option)
        .fontSize(15)
        .fontColor(this.getOptionTextColor(optIndex))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(this.getOptionCardBg(optIndex))
    .borderRadius(10)
    .border({ width: 1, color: this.getOptionCardBorder(optIndex) })
    .margin({ bottom: 12 })
    .onClick(() => {
      if (!this.isAnswered) {
        this.onSelectOption(optIndex)
      }
    })
  }

  // 选项颜色逻辑
  getOptionBgColor(optIndex: number): string | Color {
    if (!this.isAnswered) return '#EDF4FF'
    const correct = this.questions[this.currentIndex].options.indexOf(this.questions[this.currentIndex].answer)
    if (optIndex === correct) return '#E8F8E8'
    if (optIndex === this.selectedOption && optIndex !== correct) return '#FFE8E8'
    return '#EDF4FF'
  }

  getOptionBorderColor(optIndex: number): string | Color {
    if (!this.isAnswered) return '#4A90D9'
    const correct = this.questions[this.currentIndex].options.indexOf(this.questions[this.currentIndex].answer)
    if (optIndex === correct) return '#7ED321'
    if (optIndex === this.selectedOption && optIndex !== correct) return '#E74C3C'
    return '#CCCCCC'
  }

  getOptionTextColor(optIndex: number): string | Color {
    if (!this.isAnswered) return '#4A90D9'
    const correct = this.questions[this.currentIndex].options.indexOf(this.questions[this.currentIndex].answer)
    if (optIndex === correct) return '#7ED321'
    if (optIndex === this.selectedOption && optIndex !== correct) return '#E74C3C'
    return '#CCCCCC'
  }

  getOptionCardBg(optIndex: number): string | Color {
    if (!this.isAnswered) return '#FFFFFF'
    const correct = this.questions[this.currentIndex].options.indexOf(this.questions[this.currentIndex].answer)
    if (optIndex === correct) return '#F0FFF0'
    if (optIndex === this.selectedOption && optIndex !== correct) return '#FFF0F0'
    return '#FFFFFF'
  }

  getOptionCardBorder(optIndex: number): string | Color {
    if (!this.isAnswered) return '#E8E8E8'
    const correct = this.questions[this.currentIndex].options.indexOf(this.questions[this.currentIndex].answer)
    if (optIndex === correct) return '#7ED321'
    if (optIndex === this.selectedOption && optIndex !== correct) return '#E74C3C'
    return '#E8E8E8'
  }

  @Builder
  quizHeader() {
    Column() {
      // 进度条
      Row() {
        Progress({ value: this.currentIndex + 1, total: this.questions.length, type: ProgressType.Linear })
          .width('100%')
          .height(4)
          .color('#4A90D9')
          .style({ strokeWidth: 4, strokeRadius: 2 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 4 })

      // 计时器
      Row() {
        Text(this.formatTime())
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.timeLeft <= 10 ? '#E74C3C' : '#4A90D9')

        Blank().width(8)

        Text(`${this.score} / ${this.questions.length} 已答对`)
          .fontSize(13)
          .fontColor('#999999')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 12, bottom: 4 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }


  getScoreMessage(): string {
    const rate = this.score / this.questions.length
    if (rate === 1) return '太厉害了，全部答对！'
    if (rate >= 0.8) return '非常棒，继续保持！'
    if (rate >= 0.6) return '不错哦，再接再厉！'
    if (rate >= 0.4) return '还需努力，多读诗词~'
    return '加油，多学几首诗词吧！'
  }
}
