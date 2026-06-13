import { ApiService } from '../services/ApiService'
import { DatabaseHelper } from '../model/DatabaseHelper'
import { SocialPost, CheckInRecord } from '../common/Types'
import { SocialPostCard } from '../components/SocialPostCard'
import { EmptyState } from '../components/EmptyState'
import { Debouncer } from '../utils/Debouncer'
import { promptAction } from '@kit.ArkUI'

@Component
export struct SocialPage {
  @State posts: SocialPost[] = []
  @State isLoading: boolean = false
  @State isCheckedIn: boolean = false
  @State consecutiveDays: number = 0
  @State inputText: string = ''
  @State currentPage: number = 1
  @State hasMore: boolean = true
  @State checkinHistory: CheckInRecord[] = []

  private api: ApiService = ApiService.getInstance()
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()
  private likeDebouncer: Debouncer = new Debouncer(200)

  async aboutToAppear(): Promise<void> {
    await this.loadCheckinStatus()
    await this.loadCheckinHistory()
    await this.loadPosts()
  }

  async loadCheckinStatus(): Promise<void> {
    try {
      this.isCheckedIn = await this.dbHelper.isCheckedInToday()
      this.consecutiveDays = await this.dbHelper.getConsecutiveCheckinDays()
    } catch (err) {
      console.error('SocialPage', '加载打卡状态失败')
    }
  }

  async loadCheckinHistory(): Promise<void> {
    try {
      this.checkinHistory = await this.dbHelper.getCheckinHistory(5, 0)
    } catch (err) {
      console.error('SocialPage', '加载打卡历史失败')
    }
  }

  async doCheckin(): Promise<void> {
    const text = this.inputText.trim()
    if (!text) {
      promptAction.showToast({ message: '请输入打卡内容', duration: 1500 })
      return
    }
    // 从输入中提取诗词标题（匹配《》或取前 15 字）
    const titleMatch = text.match(/《(.+?)》/)
    const poemTitle = titleMatch ? titleMatch[1] : text.substring(0, 15)
    try {
      const success = await this.dbHelper.doCheckin(poemTitle, text)
      if (success) {
        this.isCheckedIn = true
        this.inputText = ''
        this.consecutiveDays = await this.dbHelper.getConsecutiveCheckinDays()
        await this.loadCheckinHistory()
        promptAction.showToast({ message: '打卡成功！连续' + this.consecutiveDays + '天', duration: 1500 })
      }
    } catch (err) {
      promptAction.showToast({ message: '打卡失败，请重试', duration: 1500 })
    }
  }

  async loadPosts(reset: boolean = true): Promise<void> {
    if (this.isLoading) return
    if (!reset && !this.hasMore) return
    this.isLoading = true
    if (reset) {
      this.currentPage = 1
      this.hasMore = true
    }
    try {
      const res = await this.api.getSocialPosts(this.currentPage, 10)
      if (res.code === 0 && res.data) {
        const newList = res.data.list.map((item: SocialPost) => new SocialPost(
          item.id, item.content, item.likes, item.isLiked, item.createTime
        ))
        if (reset) {
          this.posts = newList
        } else {
          this.posts = this.posts.concat(newList)
        }
        this.hasMore = res.data.list.length >= 10
        if (res.data.list.length > 0) {
          this.currentPage++
        }
      } else {
        if (this.posts.length === 0) {
          this.posts = this.getMockPosts()
        }
      }
    } catch (err) {
      if (this.posts.length === 0) {
        this.posts = this.getMockPosts()
      }
      promptAction.showToast({ message: '网络异常，已加载本地数据', duration: 2000 })
    } finally {
      this.isLoading = false
    }
  }

  getMockPosts(): SocialPost[] {
    return [
      new SocialPost(1, '今天读了李白的《静夜思》，「举头望明月，低头思故乡」写得真好啊！打卡学习~', 12, false, '2026-06-11 10:30'),
      new SocialPost(2, '推荐苏轼的《水调歌头》，每次读都有不同的感受。坚持打卡！', 8, true, '2026-06-10 15:20'),
      new SocialPost(3, '白居易的《琵琶行》太长了，但「大弦嘈嘈如急雨，小弦切切如私语」确实精彩。打卡~', 5, false, '2026-06-10 09:15')
    ]
  }

  onToggleLike(post: SocialPost): void {
    // 乐观更新：UI 即时反馈
    post.isLiked = !post.isLiked
    if (post.isLiked) {
      post.likes++
    } else {
      post.likes--
    }

    // 防抖延迟 API 调用
    this.likeDebouncer.run(async () => {
      try {
        if (post.isLiked) {
          await this.api.likePost(post.id)
        } else {
          await this.api.unlikePost(post.id)
        }
      } catch (err) {
        // 失败时回滚
        post.isLiked = !post.isLiked
        if (post.isLiked) {
          post.likes++
        } else {
          post.likes--
        }
        promptAction.showToast({ message: '操作失败', duration: 1000 })
      }
    })
  }

  async publish(): Promise<void> {
    const text = this.inputText.trim()
    if (!text) return
    try {
      const res = await this.api.publishPost(text)
      if (res.code === 0 && res.data) {
        this.posts.unshift(res.data)
        promptAction.showToast({ message: '发布成功', duration: 1500 })
      }
    } catch (err) {
      this.posts.unshift(new SocialPost(Date.now(), text, 0, false, new Date().toLocaleString()))
    }
    this.inputText = ''
  }

  build() {
    Column() {
      this.headerBar()
      this.checkinBar()

      // 打卡历史
      if (this.checkinHistory.length > 0) {
        this.checkinHistorySection()
      }

      if (this.posts.length === 0 && !this.isLoading) {
        EmptyState({
          icon: '💬',
          title: '暂无打卡动态',
          subtitle: '成为第一个打卡分享诗词感悟的人吧~',
          showRetry: false
        }).layoutWeight(1)
      } else {
        List({ space: 8 }) {
          ForEach(this.posts, (post: SocialPost) => {
            ListItem() {
              SocialPostCard({
                post: post,
                showDivider: true,
                onLikeClick: (p: SocialPost) => { this.onToggleLike(p) }
              })
            }
          }, (post: SocialPost) => post.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 12, right: 12, top: 8 })
        .scrollBar(BarState.Off)
        .onReachEnd(() => { this.loadPosts(false) })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  headerBar() {
    Row() {
      Text('打卡圈')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Blank().width(8)
      Text('分享你的诗词学习打卡')
        .fontSize(12)
        .fontColor('#999999')
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  checkinBar() {
    Column() {
      Row() {
        Text('📅').fontSize(20)
        Blank().width(8)
        Column() {
          if (this.isCheckedIn) {
            Text('今日已打卡')
              .fontSize(14).fontColor('#7ED321').fontWeight(FontWeight.Medium)
          } else {
            Text('今日未打卡')
              .fontSize(14).fontColor('#999999').fontWeight(FontWeight.Medium)
          }
          Text('连续打卡 ' + this.consecutiveDays + ' 天')
            .fontSize(11).fontColor('#F5A623')
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        if (!this.isCheckedIn) {
          Button('签到打卡')
            .fontSize(13).fontColor('#FFFFFF').backgroundColor('#4A90D9')
            .borderRadius(16).height(34).padding({ left: 16, right: 16 })
            .onClick(() => { this.doCheckin() })
        } else {
          Text('✓').fontSize(22).fontColor('#7ED321')
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      if (!this.isCheckedIn) {
        Row() {
          TextInput({ placeholder: '今天读了哪首诗词？分享感悟...(用《》标注诗名)', text: this.inputText })
            .fontSize(13).backgroundColor('#F5F5F5').borderRadius(16).height(36)
            .layoutWeight(1).padding({ left: 12, right: 12 }).maxLength(200)
            .onChange((value: string) => { this.inputText = value })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 0, bottom: 12 })
      }
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  checkinHistorySection() {
    Column() {
      Text('我的打卡记录')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .padding({ left: 16, top: 12, bottom: 8 })
        .width('100%')

      ForEach(this.checkinHistory, (record: CheckInRecord, index: number) => {
        Row() {
          Text('📖').fontSize(16)
          Blank().width(10)
          Column() {
            if (record.poemTitle) {
              Text('《' + record.poemTitle + '》')
                .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333333')
            }
            if (record.content) {
              Text(record.content)
                .fontSize(12).fontColor('#666666')
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 2 })
            }
            Text(record.date)
              .fontSize(11).fontColor('#999999')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')

        if (index < this.checkinHistory.length - 1) {
          Divider().strokeWidth(0.5).color('#F0F0F0').margin({ left: 42 })
        }
      })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
    .borderRadius(10)
    .margin({ left: 12, right: 12 })
  }
}
