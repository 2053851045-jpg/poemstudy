import { router } from '@kit.ArkUI'
import { NavHeader } from '../components/NavHeader'

/**
 * 设置页面
 * 提供应用设置选项，包括：
 * - 每日提醒设置
 * - 缓存管理
 * - 关于页面
 */
@Entry
@Component
struct SettingsPage {
  @State dailyReminder: boolean = true
  @State cacheSize: string = '12.5 MB'

  build() {
    Column() {
      // 导航栏
      NavHeader({
        title: '设置',
        showBack: true,
        backCallback: () => { router.back() }
      })

      // 通用设置
      Column() {
        this.sectionTitle('通用设置')

        // 每日推荐提醒
        Row() {
          Text('📅').fontSize(18)
          Blank().width(12)
          Column() {
            Text('每日推荐提醒').fontSize(15).fontColor('#333333')
            Text('每天推送一首诗词推荐').fontSize(12).fontColor('#999999').margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.dailyReminder })
            .onChange((value: boolean) => {
              this.dailyReminder = value
            })
        }
        .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })

        // 测验计时音效
        Row() {
          Text('🔔').fontSize(18)
          Blank().width(12)
          Column() {
            Text('测验计时提示音').fontSize(15).fontColor('#333333')
            Text('答题时间过半和快结束时提醒').fontSize(12).fontColor('#999999').margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: true })
        }
        .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })

        // 自动播放朗诵
        Row() {
          Text('🔊').fontSize(18)
          Blank().width(12)
          Column() {
            Text('自动播放朗诵').fontSize(15).fontColor('#333333')
            Text('进入详情页自动朗读诗词').fontSize(12).fontColor('#999999').margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: false })
        }
        .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
      }
      .width('100%').backgroundColor('#FFFFFF').borderRadius(10).margin({ top: 12, left: 12, right: 12 })

      // 数据管理
      Column() {
        this.sectionTitle('数据管理')

        Row() {
          Text('🗄️').fontSize(18)
          Blank().width(12)
          Text('清除缓存').fontSize(15).fontColor('#333333').layoutWeight(1)
          Text(this.cacheSize).fontSize(13).fontColor('#999999')
          Blank().width(4)
          Text('>').fontSize(14).fontColor('#CCCCCC')
        }
        .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
        .onClick(() => {
          this.cacheSize = '0 MB'
        })

        Row() {
          Text('📤').fontSize(18)
          Blank().width(12)
          Text('导出学习记录').fontSize(15).fontColor('#333333').layoutWeight(1)
          Text('>').fontSize(14).fontColor('#CCCCCC')
        }
        .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
      }
      .width('100%').backgroundColor('#FFFFFF').borderRadius(10).margin({ top: 12, left: 12, right: 12 })

      // 关于
      Column() {
        this.sectionTitle('关于')

        Row() {
          Text('ℹ️').fontSize(18)
          Blank().width(12)
          Text('应用版本').fontSize(15).fontColor('#333333').layoutWeight(1)
          Text('v1.0.0').fontSize(13).fontColor('#999999')
        }
        .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })

        Row() {
          Text('📄').fontSize(18)
          Blank().width(12)
          Text('隐私政策').fontSize(15).fontColor('#333333').layoutWeight(1)
          Text('>').fontSize(14).fontColor('#CCCCCC')
        }
        .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })

        Row() {
          Text('📋').fontSize(18)
          Blank().width(12)
          Text('用户协议').fontSize(15).fontColor('#333333').layoutWeight(1)
          Text('>').fontSize(14).fontColor('#CCCCCC')
        }
        .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
      }
      .width('100%').backgroundColor('#FFFFFF').borderRadius(10).margin({ top: 12, left: 12, right: 12 })

      Blank().layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  sectionTitle(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor('#999999')
      .padding({ left: 16, right: 16, top: 14, bottom: 8 })
      .width('100%')
  }
}