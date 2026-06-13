import { Poem } from '../common/Types'

@Component
export struct PoemListItem {
  @Prop poem: Poem
  onItemClick: (poem: Poem) => void = () => {}

  build() {
    Column() {
      Row() {
        // 左侧：标题 + 作者信息
        Column() {
          Text(this.poem.title)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Blank().height(4)

          Row() {
            Text(this.poem.author || '佚名')
              .fontSize(13)
              .fontColor('#4A90D9')

            if (this.poem.dynasty) {
              Text(' · ')
                .fontSize(13)
                .fontColor('#CCCCCC')
              Text(this.poem.dynasty)
                .fontSize(13)
                .fontColor('#999999')
            }
          }

          // 内容预览
          if (this.poem.content) {
            Blank().height(6)
            Text(this.poem.content)
              .fontSize(13)
              .fontColor('#666666')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .lineHeight(20)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 右侧箭头
        Text('>')
          .fontSize(16)
          .fontColor('#CCCCCC')
          .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .alignItems(VerticalAlign.Center)

      // 分割线
      Divider()
        .strokeWidth(0.5)
        .color('#EEEEEE')
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      if (this.onItemClick) {
        this.onItemClick(this.poem)
      }
    })
  }
}
