import { DatabaseHelper } from '../model/DatabaseHelper'
import { SocialFeedItem, PostComment } from '../common/Types'
import { SocialPostCard } from '../components/SocialPostCard'
import { StorageHelper } from '../utils/StorageHelper'
import { KEY_USER_ID, KEY_USER_INFO } from '../common/Constants'

/**
 * 打卡圈 — 发帖 + Feed + 多级评论系统
 *
 * 功能：
 * - 发帖（公开打卡分享）
 * - Feed 流展示所有帖子
 * - 帖子 ❤️ 点赞
 * - 评论（含嵌套回复）
 * - 评论 ❤️ 点赞
 *
 * 考点：
 * - 数据库 CRUD（social_post + post_comment 表）
 * - @Observed + @ObjectLink 深度响应
 * - 多级评论（parent_id 嵌套）
 * - 用户昵称显示
 */
@Component
export struct SocialPage {
  @State feed: SocialFeedItem[] = []
  @State isLoading: boolean = false
  @State postText: string = ''
  @State currentNickname: string = '诗词爱好者'

  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()

  async aboutToAppear(): Promise<void> {
    this.loadNickname()
    await this.loadFeed()
  }

  loadNickname(): void {
    try {
      const infoStr = StorageHelper.get<string>(KEY_USER_INFO) ?? ''
      if (infoStr) {
        const info = JSON.parse(infoStr) as Record<string, Object>
        if (info.nickname) {
          this.currentNickname = info.nickname as string
        }
      }
    } catch (e) {
      // ignore
    }
  }

  /** 获取当前 userId */
  private getUserId(): number {
    return StorageHelper.get<number>(KEY_USER_ID) ?? 0
  }

  /** 加载 Feed */
  async loadFeed(): Promise<void> {
    if (this.isLoading) return
    this.isLoading = true
    try {
      const posts = await this.dbHelper.getPosts(50, 0)
      // 为每个帖子加载评论
      for (const post of posts) {
        post.comments = await this.dbHelper.getCommentsByPostId(post.id)
      }
      this.feed = posts
    } catch (err) {
      console.error('SocialPage', '加载失败')
    } finally {
      this.isLoading = false
    }
  }

  /** 发帖 */
  async doPost(): Promise<void> {
    const text = this.postText.trim()
    if (!text) return
    const userId = this.getUserId()
    try {
      const postId = await this.dbHelper.createPost(userId, this.currentNickname, text)
      // 插入后重新加载 Feed
      this.postText = ''
      await this.loadFeed()
    } catch (err) {
      console.error('SocialPage', '发帖失败')
    }
  }

  /** 帖子点赞 */
  handleLikePost(postId: number): void {
    this.dbHelper.updatePostLikes(postId, 1)
  }

  /** 评论点赞 */
  handleLikeComment(commentId: number): void {
    this.dbHelper.updateCommentLikes(commentId, 1)
  }

  /** 添加评论/回复 */
  async handleAddComment(postId: number, content: string, parentId: number): Promise<void> {
    const userId = this.getUserId()
    try {
      await this.dbHelper.addComment(postId, userId, this.currentNickname, content, parentId)
      // 刷新此帖子的评论
      for (const post of this.feed) {
        if (post.id === postId) {
          post.comments = await this.dbHelper.getCommentsByPostId(postId)
          post.commentCount = post.comments.length
          break
        }
      }
    } catch (err) {
      console.error('SocialPage', '评论失败')
    }
  }

  build() {
    Column() {
      // ===== 标题栏 =====
      Row() {
        Text('🏮 打卡圈')
          .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#3A3A3A')
        Blank().width(8)
        Text('分享诗词学习点滴')
          .fontSize(12).fontColor('#8B7355')
      }
      .width('100%').height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FAF8F5')

      // ===== 发帖栏 =====
      Row() {
        TextInput({ placeholder: '分享你今日的诗词感悟...', text: this.postText })
          .fontSize(14).backgroundColor('#FFFFFF').borderRadius(18)
          .height(40).layoutWeight(1).padding({ left: 14, right: 14 })
          .onChange((v: string) => { this.postText = v })
          .onSubmit(() => { this.doPost() })
        Blank().width(8)
        Text('📤 发布')
          .fontSize(14).fontColor('#FFFFFF')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor(this.postText.trim().length > 0 ? '#8B4513' : '#CCCCCC')
          .borderRadius(18)
          .onClick(() => { if (this.postText.trim().length > 0) this.doPost() })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor('#FAF8F5')

      // ===== Feed 列表 =====
      if (this.isLoading && this.feed.length === 0) {
        Column() {
          LoadingProgress().width(28).height(28).color('#8B4513')
          Blank().height(10)
          Text('加载中...').fontSize(13).fontColor('#8B7355')
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.feed.length === 0) {
        Column() {
          Text('🏮').fontSize(48)
          Blank().height(12)
          Text('还没有打卡记录')
            .fontSize(16).fontColor('#3A3A3A')
          Blank().height(6)
          Text('成为第一个分享诗词感悟的人吧')
            .fontSize(13).fontColor('#8B7355')
        }
        .width('100%').layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.feed, (item: SocialFeedItem) => {
            ListItem() {
              SocialPostCard({
                item: item,
                onLikePost: (postId: number) => { this.handleLikePost(postId) },
                onLikeComment: (commentId: number) => { this.handleLikeComment(commentId) },
                onAddComment: (postId: number, content: string, parentId: number) => {
                  this.handleAddComment(postId, content, parentId)
                }
              })
            }
          }, (item: SocialFeedItem) => item.id.toString())
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
}
