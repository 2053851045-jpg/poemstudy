import { router } from '@kit.ArkUI'
import { StorageHelper } from '../utils/StorageHelper'
import { DatabaseHelper } from '../model/DatabaseHelper'
import { DynastyStat, DynastyStatWithColor, CategoryStat } from '../common/Types'
import { KEY_USER_INFO, KEY_TOKEN, KEY_DB_READY } from '../common/Constants'
import { StatCard } from '../components/StatCard'
import { MenuItemComp } from '../components/MenuItem'

@Component
export struct ProfilePage {
  @State nickname: string = '诗词爱好者'
  @State totalPoems: number = 0
  @State favoriteCount: number = 0
  @State quizCount: number = 0
  @State avgScore: number = 0
  @State dynastyStats: DynastyStatWithColor[] = []
  @State categoryStats: CategoryStat[] = []
  @State isLoading: boolean = true
  @State dailyQuote: string = ''

  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()
  private quotes: string[] = [
    '腹有诗书气自华，最是书香能致远。',
    '读书破万卷，下笔如有神。',
    '纸上得来终觉浅，绝知此事要躬行。',
    '学如逆水行舟，不进则退。',
    '一日不读书，胸臆无佳想。'
  ]

  aboutToAppear(): void {
    this.loadUserInfo()
    this.loadStats()
    this.dailyQuote = this.quotes[Math.floor(Math.random() * this.quotes.length)]
  }

  loadUserInfo(): void {
    try {
      const userInfoStr: string = StorageHelper.get<string>(KEY_USER_INFO) ?? ''
      if (userInfoStr) {
        const userInfo: Record<string, string> = JSON.parse(userInfoStr) as Record<string, string>
        if (userInfo.nickname) {
          this.nickname = userInfo.nickname
        }
      }
    } catch (err) {
      // ignore
    }
  }

  async loadStats(): Promise<void> {
    this.isLoading = true
    try {
      const poemCount = await this.dbHelper.getPoemCount()
      const favCount = await this.dbHelper.getFavoriteCount()
      const quizTotal = await this.dbHelper.getQuizCount()
      const dynasties = await this.dbHelper.getDynastyStats()
      const categories = await this.dbHelper.getCategoryStats()

      this.totalPoems = poemCount
      this.favoriteCount = favCount
      this.quizCount = quizTotal

      // 计算平均分
      if (quizTotal > 0) {
        const history = await this.dbHelper.getQuizHistory(quizTotal)
        const total = history.reduce((sum, r) => sum + r.score, 0)
        this.avgScore = Math.round((total / quizTotal) * 10) / 10
      }

      // 朝代统计 + 颜色映射
      const colors = ['#4A90D9', '#F5A623', '#7ED321', '#E74C3C', '#9B59B6', '#1ABC9C']
      this.dynastyStats = dynasties.map((item: DynastyStat, index: number): DynastyStatWithColor => ({
        dynasty: item.dynasty,
        count: item.count,
        color: colors[index % colors.length]
      }))

      this.categoryStats = categories
    } catch (err) {
      console.error('ProfilePage', '加载统计数据失败')
    } finally {
      this.isLoading = false
    }
  }

  onLogout(): void {
    StorageHelper.set(KEY_TOKEN, '')
    StorageHelper.set(KEY_USER_INFO, '')
    router.replaceUrl({ url: 'pages/LoginPage' })
  }

  onViewFavorites(): void {
    router.pushUrl({ url: 'pages/FavoritesPage' })
  }

  build() {
    Column() {
      // 标题栏
      this.headerBar()

      Scroll() {
        Column() {
          // 用户信息卡片
          this.userCard()

          // 每日签语
          this.dailyQuoteCard()

          // 数据概览
          this.statsOverview()

          // 朝代分布图表
          if (this.dynastyStats.length > 0) {
            this.dynastyChart()
          }

          // 分类统计
          if (this.categoryStats.length > 0) {
            this.categorySection()
          }

          // 功能入口
          this.menuSection()

          Blank().height(40)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  headerBar() {
    Row() {
      Text('我的')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  userCard() {
    Row() {
      // 头像
      Column() {
        Image($r('app.media.icon_profile'))
          .width(32).height(32)
          .fillColor('#4A90D9')
      }
      .width(60).height(60)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#EDF4FF')
      .borderRadius(30)

      Blank().width(14)

      Column() {
        Text(this.nickname)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text('热爱诗词，品味经典')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
  }

  @Builder
  statsOverview() {
    Row() {
      StatCard({ label: '诗词总数', value: `${this.totalPoems}`, color: '#4A90D9', cardWidth: '22%' })
      StatCard({ label: '收藏数', value: `${this.favoriteCount}`, color: '#F5A623', cardWidth: '22%' })
      StatCard({ label: '测验次数', value: `${this.quizCount}`, color: '#7ED321', cardWidth: '22%' })
      StatCard({ label: '平均分', value: this.quizCount > 0 ? `${this.avgScore}` : '-', color: '#E74C3C', cardWidth: '22%' })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 12, right: 12, top: 12 })
  }

  @Builder
  dailyQuoteCard() {
    Row() {
      Text('💡')
        .fontSize(16)
      Blank().width(8)
      Text(this.dailyQuote)
        .fontSize(13)
        .fontColor('#F5A623')
        .lineHeight(20)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFF9F0')
    .borderRadius(10)
    .margin({ left: 12, right: 12, top: 8 })
  }

  @Builder
  dynastyChart() {
    Column() {
      Text('朝代分布')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 12 })

      // 使用 Grid 展示柱状图
      Row() {
        ForEach(this.dynastyStats, (item: DynastyStatWithColor) => {
          Column() {
            // 数值
            Text(item.count.toString())
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(item.color)
              .margin({ bottom: 4 })

            // 柱状条
            Column()
              .width(36)
              .height(Math.max(item.count * 4, 8))
              .backgroundColor(item.color)
              .borderRadius({ topLeft: 4, topRight: 4 })

            // 标签
            Text(item.dynasty)
              .fontSize(11)
              .fontColor('#666666')
              .margin({ top: 6 })
          }
          .alignItems(HorizontalAlign.Center)
          .layoutWeight(1)
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
  }

  @Builder
  categorySection() {
    Column() {
      Text('分类统计')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 12 })

      ForEach(this.categoryStats, (item: CategoryStat) => {
        Row() {
          Text(item.category || '未分类')
            .fontSize(14)
            .fontColor('#333333')
            .layoutWeight(1)

          Text(item.count.toString())
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4A90D9')

          Blank().width(10)

          Progress({ value: item.count, total: this.totalPoems, type: ProgressType.Linear })
            .width(80)
            .height(6)
            .color('#4A90D9')
            .style({ strokeWidth: 6, strokeRadius: 3 })
        }
        .width('100%')
        .margin({ bottom: 10 })
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
  }

  @Builder
  menuSection() {
    Column() {
      MenuItemComp({ icon: '❤️', label: '我的收藏', itemClick: () => { this.onViewFavorites() } })
      Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 44 })
      MenuItemComp({ icon: '📝', label: '测验记录', itemClick: () => {
        router.pushUrl({ url: 'pages/QuizHistoryPage' })
      } })
      Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 44 })
      MenuItemComp({ icon: '⚙️', label: '应用设置', itemClick: () => {
        router.pushUrl({ url: 'pages/SettingsPage' })
      } })
      Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 44 })
      MenuItemComp({ icon: '🚪', label: '退出登录', textColor: '#E74C3C', itemClick: () => { this.onLogout() } })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 12, right: 12, top: 12 })
  }
}

