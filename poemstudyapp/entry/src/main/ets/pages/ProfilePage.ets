import { router } from '@kit.ArkUI'
import { StorageHelper } from '../utils/StorageHelper'
import { DatabaseHelper } from '../model/DatabaseHelper'
import { DynastyStat, DynastyStatWithColor, CategoryStat } from '../common/Types'
import { KEY_USER_INFO, KEY_TOKEN, KEY_USER_ID } from '../common/Constants'
import { StatCard } from '../components/StatCard'
import { MenuItemComp } from '../components/MenuItem'

/**
 * 个人中心 — 中式古典美学风格
 * 显示统计数据、朝代分布图表、功能入口
 */
@Component
export struct ProfilePage {
  @State nickname: string = '诗词爱好者'
  @State userRole: string = ''
  @State totalPoems: number = 0
  @State favoriteCount: number = 0
  @State quizCount: number = 0
  @State avgScore: number = 0
  @State dynastyStats: DynastyStatWithColor[] = []
  @State categoryStats: CategoryStat[] = []
  @State isLoading: boolean = true
  @State dailyQuote: string = ''
  @State loadError: boolean = false

  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()
  private quotes: string[] = [
    '腹有诗书气自华，最是书香能致远。',
    '读书破万卷，下笔如有神。',
    '纸上得来终觉浅，绝知此事要躬行。',
    '学如逆水行舟，不进则免。',
    '一日不读书，胸臆无佳想。',
    '问渠那得清如许，为有源头活水来。',
  ]

  aboutToAppear(): void {
    this.loadUserInfo()
    this.forceRefresh()
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
        if (userInfo.role) {
          this.userRole = userInfo.role
        }
      }
    } catch (err) {
      // ignore
    }
  }

  /** 强制刷新数据（每次切换到此Tab都重新查询） */
  async forceRefresh(): Promise<void> {
    this.isLoading = true
    this.loadError = false
    try {
      // 确保数据库已就绪
      await this.dbHelper.ensureReady()
      const poemCount = await this.dbHelper.getPoemCount()
      const favCount = await this.dbHelper.getFavoriteCount()
      const quizTotal = await this.dbHelper.getQuizCount()
      const dynasties = await this.dbHelper.getDynastyStats()
      const categories = await this.dbHelper.getCategoryStats()

      this.totalPoems = poemCount
      this.favoriteCount = favCount
      this.quizCount = quizTotal

      if (quizTotal > 0) {
        const history = await this.dbHelper.getQuizHistory(quizTotal)
        const total = history.reduce((sum, r) => sum + r.score, 0)
        this.avgScore = Math.round((total / quizTotal) * 10) / 10
      } else {
        this.avgScore = 0
      }

      const colors = ['#C5A55A', '#8B4513', '#5B8C5A', '#CC3333', '#4A6FA5', '#8B5E3C']
      this.dynastyStats = dynasties.map((item: DynastyStat, index: number): DynastyStatWithColor => ({
        dynasty: item.dynasty,
        count: item.count,
        color: colors[index % colors.length]
      }))

      this.categoryStats = categories
    } catch (err) {
      console.error('ProfilePage', '加载统计数据失败', JSON.stringify(err))
      this.loadError = true
    } finally {
      this.isLoading = false
    }
  }

  getRoleLabel(role: string): string {
    switch (role) {
      case 'teacher': return '先生'
      case 'student': return '学子'
      case 'guest': return '游客'
      default: return '学子'
    }
  }

  getRoleColor(role: string): string {
    switch (role) {
      case 'teacher': return '#C5A55A'
      case 'student': return '#4A6FA5'
      case 'guest': return '#999999'
      default: return '#4A6FA5'
    }
  }

  onLogout(): void {
    // 如果是游客，清理数据库中的全部数据
    if (StorageHelper.isGuest()) {
      const guestId: number = StorageHelper.get<number>(KEY_USER_ID) ?? 0
      if (guestId !== 0) {
        const dbHelper = DatabaseHelper.getInstance()
        dbHelper.cleanGuestData(guestId)
      }
    }
    StorageHelper.set(KEY_TOKEN, '')
    StorageHelper.set(KEY_USER_INFO, '')
    StorageHelper.set(KEY_USER_ID, '')
    router.replaceUrl({ url: 'pages/LoginPage' })
  }

  onViewFavorites(): void {
    router.pushUrl({ url: 'pages/FavoritesPage' })
  }

  build() {
    Column() {
      this.headerBar()

      if (this.loadError) {
        // 错误提示 + 重试
        Column() {
          Text('📜 数据加载异常')
            .fontSize(15).fontColor('#CC3333').margin({ bottom: 8 })
          Text('点击重试')
            .fontSize(13).fontColor('#8B4513').onClick(() => { this.forceRefresh() })
        }
        .width('100%').padding(20).backgroundColor('#FFF5F5')
      }

      Scroll() {
        Column() {
          this.userCard()
          this.dailyQuoteCard()

          if (this.isLoading) {
            Column() {
              LoadingProgress().width(28).height(28).color('#8B4513')
              Blank().height(10)
              Text('加载数据中...').fontSize(13).fontColor('#999999')
            }
            .width('100%').padding(40).alignItems(HorizontalAlign.Center)
          } else {
            this.statsOverview()
            if (this.dynastyStats.length > 0) {
              this.dynastyChart()
            }
            if (this.categoryStats.length > 0) {
              this.categorySection()
            }
          }

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
    .backgroundColor('#F5F0E8')  // 宣纸底色
  }

  @Builder
  headerBar() {
    Row() {
      Text('我的')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#3A3A3A')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FAF8F5')
  }

  @Builder
  userCard() {
    Row() {
      Column() {
        Image($r('app.media.icon_profile'))
          .width(32).height(32)
          .fillColor('#8B4513')
      }
      .width(60).height(60)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#EDE4D8')
      .borderRadius(30)

      Blank().width(14)

      Column() {
        Text(this.nickname)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#3A3A3A')
        Text('热爱诗词 · 品味经典')
          .fontSize(12)
          .fontColor('#8B7355')
          .margin({ top: 4 })
        if (this.userRole) {
          Row() {
            Text(this.getRoleLabel(this.userRole))
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(this.getRoleColor(this.userRole))
              .borderRadius(8)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          }
          .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 12, right: 12, top: 12 })
    .shadow({ radius: 2, color: '#20000000', offsetY: 1 })
  }

  @Builder
  statsOverview() {
    Row() {
      StatCard({ label: '诗词', value: `${this.totalPoems}`, color: '#8B4513', cardWidth: '22%' })
      StatCard({ label: '收藏', value: `${this.favoriteCount}`, color: '#C5A55A', cardWidth: '22%' })
      StatCard({ label: '测验', value: `${this.quizCount}`, color: '#5B8C5A', cardWidth: '22%' })
      StatCard({ label: '均分', value: this.quizCount > 0 ? `${this.avgScore}` : '-', color: '#CC3333', cardWidth: '22%' })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 12, right: 12, top: 12 })
  }

  @Builder
  dailyQuoteCard() {
    Row() {
      Text('📜')
        .fontSize(16)
      Blank().width(8)
      Text(this.dailyQuote)
        .fontSize(13)
        .fontColor('#8B4513')
        .lineHeight(20)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#F5EDE0')
    .borderRadius(8)
    .margin({ left: 12, right: 12, top: 8 })
  }

  @Builder
  dynastyChart() {
    Column() {
      Text('📊 朝代分布')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#3A3A3A')
        .margin({ bottom: 12 })

      Row() {
        ForEach(this.dynastyStats, (item: DynastyStatWithColor) => {
          Column() {
            Text(item.count.toString())
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(item.color)
              .margin({ bottom: 4 })

            Column()
              .width(36)
              .height(Math.max(item.count * 3, 6))
              .backgroundColor(item.color)
              .borderRadius({ topLeft: 4, topRight: 4 })

            Text(item.dynasty)
              .fontSize(11)
              .fontColor('#8B7355')
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
    .borderRadius(8)
    .margin({ left: 12, right: 12, top: 12 })
    .shadow({ radius: 2, color: '#20000000', offsetY: 1 })
  }

  @Builder
  categorySection() {
    Column() {
      Text('📚 分类统计')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#3A3A3A')
        .margin({ bottom: 12 })

      ForEach(this.categoryStats, (item: CategoryStat) => {
        Row() {
          Text(item.category || '未分类')
            .fontSize(14)
            .fontColor('#3A3A3A')
            .layoutWeight(1)

          Text(item.count.toString())
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8B4513')

          Blank().width(10)

          Progress({ value: item.count, total: this.totalPoems, type: ProgressType.Linear })
            .width(80)
            .height(6)
            .color('#C5A55A')
            .style({ strokeWidth: 6, strokeRadius: 3 })
        }
        .width('100%')
        .margin({ bottom: 10 })
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 12, right: 12, top: 12 })
    .shadow({ radius: 2, color: '#20000000', offsetY: 1 })
  }

  @Builder
  menuSection() {
    Column() {
      MenuItemComp({ icon: '❤️', label: '我的收藏', itemClick: () => { this.onViewFavorites() } })
      Divider().strokeWidth(0.5).color('#EDE4D8').margin({ left: 44 })
      MenuItemComp({ icon: '📝', label: '测验记录', itemClick: () => {
        router.pushUrl({ url: 'pages/QuizHistoryPage' })
      } })
      Divider().strokeWidth(0.5).color('#EDE4D8').margin({ left: 44 })
      MenuItemComp({ icon: '⚙️', label: '应用设置', itemClick: () => {
        router.pushUrl({ url: 'pages/SettingsPage' })
      } })
      Divider().strokeWidth(0.5).color('#EDE4D8').margin({ left: 44 })
      MenuItemComp({ icon: '🚪', label: '退出登录', textColor: '#CC3333', itemClick: () => { this.onLogout() } })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 12, right: 12, top: 12 })
    .shadow({ radius: 2, color: '#20000000', offsetY: 1 })
  }
}
