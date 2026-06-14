import { router } from '@kit.ArkUI'
import { DatabaseHelper } from '../model/DatabaseHelper'
import { QuizRecord } from '../common/Types'
import { NavHeader } from '../components/NavHeader'
import { EmptyState } from '../components/EmptyState'

@Entry
@Component
struct QuizHistoryPage {
  @State records: QuizRecord[] = []
  @State isLoading: boolean = true

  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()

  aboutToAppear(): void {
    this.loadHistory()
  }

  async loadHistory(): Promise<void> {
    this.isLoading = true
    try {
      this.records = await this.dbHelper.getQuizHistory(100)
    } catch (err) {
      console.error('QuizHistoryPage', '加载测验记录失败')
    } finally {
      this.isLoading = false
    }
  }

  getGradeLabel(score: number, total: number = 5): string {
    if (score >= 5) return '优秀'
    if (score >= 4) return '良好'
    if (score >= 3) return '一般'
    if (score >= 2) return '加油'
    return '继续努力'
  }

  getGradeColor(score: number, total: number = 5): string {
    if (score >= 5) return '#7ED321'
    if (score >= 4) return '#4A90D9'
    if (score >= 3) return '#F5A623'
    return '#E74C3C'
  }

  getScorePercent(score: number, total: number = 5): number {
    return (score / total) * 100
  }

  build() {
    Column() {
      // 导航栏
      NavHeader({
        title: '测验记录',
        showBack: true,
        backCallback: () => { router.back() }
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(28).height(28).color('#4A90D9')
          Blank().height(10)
          Text('加载中...')
            .fontSize(14).fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.records.length === 0) {
        EmptyState({
          icon: '📝',
          title: '暂无测验记录',
          subtitle: '去测验页挑战一下吧~',
          showRetry: false
        })
        .layoutWeight(1)
      } else {
        List({ space: 8 }) {
          ForEach(this.records, (record: QuizRecord, index: number) => {
            ListItem() {
              this.recordCard(record, index)
            }
          }, (record: QuizRecord) => record.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12, top: 8 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F0E8')
  }

  @Builder
  recordCard(record: QuizRecord, index: number) {
    Row() {
      // 序号
      Text(`${index + 1}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(30).height(30)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getGradeColor(record.score))
        .borderRadius(15)

      Blank().width(12)

      // 分数信息
      Column() {
        Row() {
          Text('得分 ')
            .fontSize(14)
            .fontColor('#333333')

          Text(record.score.toString())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4A90D9')

          Text(' / 5')
            .fontSize(13)
            .fontColor('#999999')

          Blank().width(8)

          Text(this.getGradeLabel(record.score))
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor(this.getGradeColor(record.score))
            .borderRadius(10)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        }

        Blank().height(6)

        if (record.quizTime) {
          Text(record.quizTime)
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 进度条
      Column() {
        Progress({ value: this.getScorePercent(record.score), total: 100, type: ProgressType.Ring })
          .width(36)
          .height(36)
          .color(this.getGradeColor(record.score))
          .style({ strokeWidth: 4 })
      }
      .margin({ left: 4 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
  }
}