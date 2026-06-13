/**
 * 空状态占位组件
 * 用于列表为空或数据加载失败的场景
 */
@Component
export struct EmptyState {
  @Prop icon: string = '📭'
  @Prop title: string = '暂无数据'
  @Prop subtitle: string = ''
  @Prop showRetry: boolean = false
  retryCallback: () => void = () => {}

  build() {
    Column() {
      Text(this.icon)
        .fontSize(48)

      Blank().height(12)

      Text(this.title)
        .fontSize(16)
        .fontColor('#666666')
        .fontWeight(FontWeight.Medium)

      if (this.subtitle) {
        Blank().height(6)
        Text(this.subtitle)
          .fontSize(13)
          .fontColor('#999999')
      }

      if (this.showRetry) {
        Blank().height(20)
        Button('重试')
          .fontSize(14)
          .fontColor('#4A90D9')
          .backgroundColor('#EDF4FF')
          .borderRadius(20)
          .padding({ left: 24, right: 24 })
          .onClick(() => {
            if (this.retryCallback) {
              this.retryCallback()
            }
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
