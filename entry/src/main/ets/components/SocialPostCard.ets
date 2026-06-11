/**
 * 社交帖子卡片组件
 * 用于诗圈等页面的帖子展示
 */
import { SocialPost } from '../common/Types'

@Component
export struct SocialPostCard {
  @Prop post: SocialPost
  @Prop showDivider: boolean = true
  onLikeClick: (post: SocialPost) => void = () => {}
  onCardClick: (post: SocialPost) => void = () => {}

  build() {
    Column() {
      // 帖子头部（用户信息）
      Row() {
        // 头像
        Text('👤')
          .fontSize(18)
          .width(36).height(36)
          .textAlign(TextAlign.Center)
          .backgroundColor('#EDF4FF')
          .borderRadius(18)

        Blank().width(10)

        Column() {
          Text('诗词爱好者')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          if (this.post.createTime) {
            Text(this.post.createTime)
              .fontSize(11)
              .fontColor('#999999')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 帖子内容
      Text(this.post.content)
        .fontSize(15)
        .fontColor('#333333')
        .lineHeight(22)
        .width('100%')
        .margin({ top: 10, bottom: 12 })
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 底部操作栏
      Row() {
        // 点赞按钮
        Row() {
          Text(this.post.isLiked ? '❤️' : '🤍')
            .fontSize(16)
          Blank().width(4)
          Text(this.post.likes.toString())
            .fontSize(13)
            .fontColor(this.post.isLiked ? '#E74C3C' : '#999999')
        }
        .padding({ left: 4, right: 10, top: 4, bottom: 4 })
        .onClick(() => {
          if (this.onLikeClick) {
            this.onLikeClick(this.post)
          }
        })
      }
      .width('100%')

      // 分隔线
      if (this.showDivider) {
        Blank().height(8)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick(this.post)
      }
    })
  }
}
