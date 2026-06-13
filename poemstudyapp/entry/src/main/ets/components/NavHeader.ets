/**
 * 页面顶部导航栏组件
 * 统一返回按钮 + 标题样式
 */
@Component
export struct NavHeader {
  @Prop title: string
  @Prop showBack: boolean = true
  backCallback?: () => void

  build() {
    Row() {
      if (this.showBack) {
        Text('< 返回')
          .fontSize(16)
          .fontColor('#4A90D9')
          .onClick(() => {
            if (this.backCallback) {
              this.backCallback()
            }
          })
      }

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 右侧占位，保持标题居中
      if (this.showBack) {
        Row().width(48).height(24)
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }
}