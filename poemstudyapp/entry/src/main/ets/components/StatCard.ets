﻿/**
 * 统计数据卡片组件
 * 用于个人中心等页面的数据概览
 */
@Component
export struct StatCard {
  @Prop label: string
  @Prop value: string
  @Prop color: string = '#4A90D9'
  @Prop bgColor: string = '#FFFFFF'
  @Prop cardWidth: string = '22%'
  onCardClick: () => void = () => {}

  build() {
    Column() {
      Text(this.value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.color)

      Text(this.label)
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
    .width(this.cardWidth)
    .padding({ top: 14, bottom: 14 })
    .backgroundColor(this.bgColor)
    .borderRadius(10)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (this.onCardClick) this.onCardClick()
    })
  }
}
