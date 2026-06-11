import { router } from '@kit.ArkUI'
import { DatabaseHelper } from '../model/DatabaseHelper'
import { Poem } from '../common/Types'
import { NavHeader } from '../components/NavHeader'

@Entry
@Component
struct PoemDetailPage {
  @State poem: Poem | null = null
  @State isFavorited: boolean = false
  @State isLoading: boolean = true
  private poemId: number = 0
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params && params['poemId']) {
      this.poemId = parseInt(params['poemId'])
      this.loadPoemDetail()
    }
  }

  async loadPoemDetail(): Promise<void> {
    this.isLoading = true
    try {
      this.poem = await this.dbHelper.getPoemById(this.poemId)
      if (this.poem) {
        this.isFavorited = await this.dbHelper.isFavorited(this.poemId)
      }
    } catch (err) {
      console.error('PoemDetailPage', '加载诗词详情失败')
    } finally {
      this.isLoading = false
    }
  }

  async toggleFavorite(): Promise<void> {
    if (!this.poem) return
    try {
      if (this.isFavorited) {
        const success = await this.dbHelper.removeFavorite(this.poemId)
        if (success) this.isFavorited = false
      } else {
        const success = await this.dbHelper.addFavorite(this.poemId)
        if (success) this.isFavorited = true
      }
    } catch (err) {
      console.error('PoemDetailPage', '收藏操作失败')
    }
  }

  /**
   * 根据诗词分类获取赏析摘要
   */
  getAnalysis(): string {
    if (!this.poem) return ''
    const category = this.poem.category || ''
    const dynasty = this.poem.dynasty || ''
    const author = this.poem.author || '佚名'
    if (category.includes('唐诗')) {
      return `${author}是${dynasty}著名诗人，此诗语言精练、意境深远，体现了唐代诗歌的艺术高度。`
    } else if (category.includes('宋词')) {
      return `${author}是${dynasty}著名词人，此词情感丰富、韵律优美，展现了宋词的独特魅力。`
    }
    return `${author}是${dynasty}著名文学家，此作流传千古，值得细细品味。`
  }

  build() {
    Column() {
      // 导航栏
      NavHeader({
        title: '诗词详情',
        showBack: true,
        backCallback: () => { router.back() }
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(32).height(32).color('#4A90D9')
          Blank().height(12)
          Text('加载中...')
            .fontSize(14).fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.poem) {
        Scroll() {
          Column() {
            // 标题
            Text(this.poem.title)
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .textAlign(TextAlign.Center)
              .width('100%')
              .margin({ top: 24 })

            // 作者 + 朝代
            Row() {
              Text(this.poem.author || '佚名')
                .fontSize(15)
                .fontColor('#4A90D9')
              if (this.poem.dynasty) {
                Text(' · ')
                  .fontSize(15)
                  .fontColor('#CCCCCC')
                Text(this.poem.dynasty)
                  .fontSize(15)
                  .fontColor('#999999')
              }
            }
            .margin({ top: 12 })

            // 分类标签
            if (this.poem.category) {
              Text(this.poem.category)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .backgroundColor('#4A90D9')
                .borderRadius(10)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .margin({ top: 10 })
            }

            // 分隔线
            Divider()
              .strokeWidth(0.5)
              .color('#EEEEEE')
              .margin({ top: 24, bottom: 24 })

            // 正文
            Text(this.poem.content)
              .fontSize(18)
              .fontColor('#333333')
              .lineHeight(32)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ left: 20, right: 20 })

            // 赏析区域
            this.analysisSection()

            // 操作按钮
            this.actionButtons()

            Blank().height(30)
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)

        // 底部收藏按钮
        this.favoriteButton()
      } else {
        Column() {
          Text('诗词未找到')
            .fontSize(15)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  analysisSection() {
    Column() {
      Divider()
        .strokeWidth(0.5)
        .color('#EEEEEE')
        .margin({ top: 28, bottom: 20 })

      Row() {
        Text('📖')
          .fontSize(14)
        Blank().width(6)
        Text('诗词赏析')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
      }
      .margin({ bottom: 10 })

      Text(this.getAnalysis())
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(22)
        .padding({ left: 20, right: 20 })
    }
    .width('100%')
  }

  @Builder
  actionButtons() {
    Row() {
      // 分享按钮
      Button() {
        Row() {
          Text('↗').fontSize(16)
          Blank().width(4)
          Text('分享').fontSize(13)
        }
      }
      .fontColor('#4A90D9')
      .backgroundColor('#EDF4FF')
      .borderRadius(20)
      .height(36)
      .layoutWeight(1)
      .margin({ right: 8 })

      // 朗诵按钮（占位）
      Button() {
        Row() {
          Text('🔊').fontSize(14)
          Blank().width(4)
          Text('朗诵').fontSize(13)
        }
      }
      .fontColor('#7ED321')
      .backgroundColor('#E8F8E8')
      .borderRadius(20)
      .height(36)
      .layoutWeight(1)
      .margin({ left: 8 })
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
    .margin({ top: 16 })
  }

  @Builder
  favoriteButton() {
    Row() {
      Text(this.isFavorited ? '♥' : '♡')
        .fontSize(20)
        .fontColor(this.isFavorited ? '#E74C3C' : '#999999')
      Blank().width(6)
      Text(this.isFavorited ? '已收藏' : '收藏')
        .fontSize(15)
        .fontColor(this.isFavorited ? '#E74C3C' : '#4A90D9')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F8F8F8')
    .border({ width: { top: 0.5 }, color: '#EEEEEE' })
    .onClick(() => {
      this.toggleFavorite()
    })
  }
}