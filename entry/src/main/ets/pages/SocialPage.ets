import { ApiService } from '../services/ApiService'
import { SocialPost } from '../common/Types'
import { SocialPostCard } from '../components/SocialPostCard'
import { EmptyState } from '../components/EmptyState'
import { Debouncer } from '../utils/Debouncer'
import { promptAction } from '@kit.ArkUI'

@Component
export struct SocialPage {
  @State posts: SocialPost[] = []
  @State isLoading: boolean = false
  @State inputText: string = ''
  @State currentPage: number = 1
  @State hasMore: boolean = true

  private api: ApiService = ApiService.getInstance()
  private likeDebouncer: Debouncer = new Debouncer(500)

  async aboutToAppear(): Promise<void> {
    await this.loadPosts()
  }

  /**
   * 加载帖子列表（支持分页和离线降级）
   * @param reset 是否重置列表（首页加载）
   */
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
        if (reset) {
          this.posts = res.data.list
        } else {
          this.posts = this.posts.concat(res.data.list)
        }
        this.hasMore = res.data.list.length >= 10
        if (res.data.list.length > 0) {
          this.currentPage++
        }
      } else {
        // API 返回异常时加载模拟数据
        if (this.posts.length === 0) {
          this.posts = this.getMockPosts()
        }
      }
    } catch (err) {
      // 网络失败时加载模拟数据
      if (this.posts.length === 0) {
        this.posts = this.getMockPosts()
      }
      promptAction.showToast({ message: '网络异常，已加载本地数据', duration: 2000 })
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 获取模拟帖子数据（离线模式降级方案）
   */
  getMockPosts(): SocialPost[] {
    return [
      { id: 1, content: '今天读了李白的《静夜思》，"举头望明月，低头思故乡"写得真好啊！', likes: 12, isLiked: false, createTime: '2026-06-11 10:30' },
      { id: 2, content: '推荐大家读一读苏轼的《水调歌头》，每次读都有不同的感受。', likes: 8, isLiked: true, createTime: '2026-06-10 15:20' },
      { id: 3, content: '白居易的《琵琶行》太长了，但写得确实精彩，"大弦嘈嘈如急雨，小弦切切如私语"', likes: 5, isLiked: false, createTime: '2026-06-10 09:15' },
      { id: 4, content: '有没有人喜欢辛弃疾的词？"醉里挑灯看剑，梦回吹角连营"，豪放派的代表！', likes: 15, isLiked: false, createTime: '2026-06-09 20:00' },
      { id: 5, content: '杜牧的《清明》"清明时节雨纷纷"，每年清明都会想起这首诗。', likes: 3, isLiked: false, createTime: '2026-06-09 14:50' },
      { id: 6, content: '王维的诗画一体，"大漠孤烟直，长河落日圆"，画面感太强了！', likes: 20, isLiked: false, createTime: '2026-06-08 11:00' },
      { id: 7, content: '孟浩然的《春晓》，简单几句就把春天早晨的美景写活了~', likes: 7, isLiked: false, createTime: '2026-06-07 16:30' }
    ]
  }

  /**
   * 点赞/取消点赞（带防抖，支持离线降级）
   */
  onToggleLike(post: SocialPost): void {
    this.likeDebouncer.run(async () => {
      try {
        if (post.isLiked) {
          await this.api.unlikePost(post.id)
          post.likes--
        } else {
          await this.api.likePost(post.id)
          post.likes++
        }
        post.isLiked = !post.isLiked
      } catch (err) {
        // 离线模式：本地切换状态
        post.likes += post.isLiked ? -1 : 1
        post.isLiked = !post.isLiked
      }
    })
  }

  /**
   * 发布新帖子
   */
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
      // 离线模式：本地添加
      this.posts.unshift({
        id: Date.now(),
        content: text,
        likes: 0,
        isLiked: false,
        createTime: new Date().toLocaleString()
      })
    }
    this.inputText = ''
  }

  build() {
    Column() {
      // 标题栏
      this.headerBar()

      // 发布框
      this.publishBar()

      // 帖子列表
      if (this.posts.length === 0 && !this.isLoading) {
        EmptyState({
          icon: '💬',
          title: '暂无动态',
          subtitle: '成为第一个分享诗词感悟的人吧~',
          showRetry: false
        })
        .layoutWeight(1)
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
        .onReachEnd(() => {
          this.loadPosts(false)
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  headerBar() {
    Row() {
      Text('诗圈')
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
  publishBar() {
    Row() {
      TextInput({ placeholder: '分享你的诗词感悟...', text: this.inputText })
        .fontSize(14)
        .backgroundColor('#F5F5F5')
        .borderRadius(20)
        .height(38)
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .maxLength(200)
        .onChange((value: string) => {
          this.inputText = value
        })

      if (this.inputText.trim().length > 0) {
        Text('发布')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#4A90D9')
          .borderRadius(16)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .margin({ left: 10 })
          .onClick(() => {
            this.publish()
          })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor('#FFFFFF')
  }
}




