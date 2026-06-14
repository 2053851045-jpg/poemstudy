/**
 * 社交帖子卡片 — 中式美学 · 带多级评论系统
 *
 * 功能：
 * - 显示帖子（头像/昵称/时间/内容）
 * - ❤️ 点赞（乐观更新 + DB 持久化）
 * - 💬 展开/收起评论区
 * - 评论列表（含嵌套回复）
 * - 每条评论可 ❤️ 点赞 / ↩ 回复
 * - 评论输入框
 *
 * 考点：
 * - @ObjectLink 深度响应
 * - 多级评论（parent_id 嵌套）
 * - 乐观更新
 */
import { SocialFeedItem, PostComment } from '../common/Types'

@Component
export struct SocialPostCard {
  @ObjectLink item: SocialFeedItem
  @State showComments: boolean = false
  @State commentText: string = ''
  @State replyTo: PostComment | null = null  // 当前回复目标

  onLikePost: (postId: number) => void = () => {}
  onLikeComment: (commentId: number) => void = () => {}
  onAddComment: (postId: number, content: string, parentId: number) => void = () => {}

  build() {
    Column() {
      // ===== 帖子头 =====
      Row() {
        // 头像圈
        Column() {
          Text(this.getAvatarEmoji(this.item.userId))
            .fontSize(18)
        }
        .width(36).height(36)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#EDE4D8')
        .borderRadius(18)

        Blank().width(10)

        Column() {
          Text(this.item.nickname)
            .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#3A3A3A')
          Text(this.item.createTime)
            .fontSize(11).fontColor('#8B7355')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // ===== 帖子内容 =====
      Text(this.item.content)
        .fontSize(15).fontColor('#3A3A3A')
        .lineHeight(22).width('100%')
        .margin({ top: 10, bottom: 10 })

      // ===== 操作栏 =====
      Row() {
        // ❤️ 点赞
        Row() {
          Text(this.item.isLiked ? '❤️' : '🤍')
            .fontSize(15)
          Blank().width(4)
          Text(this.item.likes > 0 ? this.item.likes.toString() : '点赞')
            .fontSize(12)
            .fontColor(this.item.isLiked ? '#CC3333' : '#8B7355')
        }
        .constraintSize({ minWidth: 56, minHeight: 30 })
        .justifyContent(FlexAlign.Center)
        .padding({ left: 10, right: 12, top: 4, bottom: 4 })
        .borderRadius(14)
        .backgroundColor(this.item.isLiked ? '#FFF0F0' : '#F5F0E8')
        .onClick(() => {
          this.item.isLiked = !this.item.isLiked
          this.item.likes += this.item.isLiked ? 1 : -1
          this.onLikePost(this.item.id)
        })

        Blank().width(10)

        // 💬 评论
        Row() {
          Text('💬')
            .fontSize(15)
          Blank().width(4)
          Text(this.item.commentCount > 0 ? this.item.commentCount.toString() : '评论')
            .fontSize(12).fontColor('#8B7355')
        }
        .constraintSize({ minWidth: 56, minHeight: 30 })
        .justifyContent(FlexAlign.Center)
        .padding({ left: 10, right: 12, top: 4, bottom: 4 })
        .borderRadius(14).backgroundColor('#F5F0E8')
        .onClick(() => {
          this.showComments = !this.showComments
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // ===== 评论区域（展开/收起） =====
      if (this.showComments) {
        Blank().height(8)
        Divider().strokeWidth(0.5).color('#EDE4D8')
        Blank().height(8)

        // 评论列表（扁平渲染，parentId=0 为主评论，>0 为嵌套回复）
        ForEach(this.item.comments, (comment: PostComment) => {
          if (comment.parentId === 0) {
            this.commentItem(comment, 0)
            // 查找该主评论的子回复
            ForEach(this.item.comments, (reply: PostComment) => {
              if (reply.parentId === comment.id) {
                this.commentItem(reply, 1)
              }
            }, (reply: PostComment) => 'r' + reply.id.toString())
          }
        }, (comment: PostComment) => comment.id.toString())

        // 评论输入
        this.commentInput()
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  /**
   * 单条评论（扁平渲染，level=0 普通，level=1 嵌套缩进）
   */
  @Builder
  commentItem(comment: PostComment, level: number) {
    Column() {
      Row() {
        if (level > 0) {
          Blank().width(24)
        }

        Text(this.getAvatarEmoji(comment.userId))
          .fontSize(14)

        Blank().width(8)

        Column() {
          Row() {
            Text(comment.nickname)
              .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#3A3A3A')
            Blank().width(8)
            Text(comment.createTime)
              .fontSize(10).fontColor('#B8A898')
          }

          Text(comment.content)
            .fontSize(14).fontColor('#3A3A3A')
            .lineHeight(20).margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // 操作：点赞 + 回复
      Row() {
        if (level > 0) {
          Blank().width(24)
        }

        Row() {
          Text(comment.isLiked ? '❤️' : '🤍')
            .fontSize(12)
          Blank().width(2)
          Text(comment.likes > 0 ? comment.likes.toString() : '')
            .fontSize(11)
            .fontColor(comment.isLiked ? '#CC3333' : '#8B7355')
        }
        .padding({ left: 6, right: 8, top: 2, bottom: 2 })
        .onClick(() => {
          comment.isLiked = !comment.isLiked
          comment.likes += comment.isLiked ? 1 : -1
          this.onLikeComment(comment.id)
        })

        Blank().width(12)

        Text('↩ 回复')
          .fontSize(11).fontColor('#8B7355')
          .onClick(() => {
            this.replyTo = comment
            this.commentText = ''
          })

        Blank().width(8)

        Text(comment.createTime)
          .fontSize(10).fontColor('#CCCCCC')
      }
      .width('100%')
      .margin({ top: 2, bottom: 4 })

      // 正在回复此评论的输入框
      if (this.replyTo?.id === comment.id) {
        Row() {
          if (level > 0) {
            Blank().width(24)
          }
          TextInput({ placeholder: '回复 ' + comment.nickname + '...', text: this.commentText })
            .fontSize(13).backgroundColor('#F5F0E8').borderRadius(16)
            .height(34).layoutWeight(1).padding({ left: 12, right: 12 })
            .onChange((v: string) => { this.commentText = v })
          Blank().width(6)
          Text('发送')
            .fontSize(13).fontColor('#8B4513')
            .onClick(() => {
              this.submitComment(comment.id)
            })
        }
        .width('100%')
        .margin({ top: 6 })
      }

      if (level === 0) {
        Divider().strokeWidth(0.3).color('#F0EBE3')
          .margin({ left: level > 0 ? 48 : 22 })
      }
    }
    .width('100%')
  }

  /**
   * 底部评论输入
   */
  @Builder
  commentInput() {
    Row() {
      TextInput({
        placeholder: this.replyTo ? '回复 ' + this.replyTo.nickname + '...' : '写评论...',
        text: this.commentText
      })
        .fontSize(14).backgroundColor('#F5F0E8').borderRadius(18)
        .height(38).layoutWeight(1).padding({ left: 14, right: 14 })
        .onChange((v: string) => { this.commentText = v })

      Blank().width(8)

      Text('发送')
        .fontSize(14).fontColor('#FFFFFF')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor(this.commentText.trim().length > 0 ? '#8B4513' : '#CCCCCC')
        .borderRadius(18)
        .onClick(() => {
          if (this.commentText.trim().length > 0) {
            this.submitComment(this.replyTo ? this.replyTo.id : 0)
          }
        })
    }
    .width('100%')
    .margin({ top: 8 })
  }

  submitComment(parentId: number): void {
    const text = this.commentText.trim()
    if (!text) return
    this.onAddComment(this.item.id, text, parentId)
    this.commentText = ''
    this.replyTo = null
  }

  getAvatarEmoji(userId: number): string {
    const emojis = ['📖', '🎋', '🌸', '🍃', '🌙', '☀️', '🪷', '🎐']
    const idx = Math.abs(userId) % emojis.length
    return emojis[idx]
  }
}
