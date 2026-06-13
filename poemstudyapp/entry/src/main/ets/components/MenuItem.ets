﻿/**
 * 菜单项组件
 * 用于个人中心功能入口列表
 */
@Component
export struct MenuItemComp {
  @Prop icon: string
  @Prop label: string
  @Prop showArrow: boolean = true
  @Prop textColor: string = '#333333'
  itemClick: () => void = () => {}

  build() {
    Row() {
      Text(this.icon)
        .fontSize(18)

      Blank().width(12)

      Text(this.label)
        .fontSize(15)
        .fontColor(this.textColor)
        .layoutWeight(1)

      if (this.showArrow) {
        Text('>')
          .fontSize(14)
          .fontColor('#CCCCCC')
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      if (this.itemClick) {
        this.itemClick()
      }
    })
  }
}
