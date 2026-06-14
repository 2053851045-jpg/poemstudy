import { router } from '@kit.ArkUI'
import { StorageHelper } from '../utils/StorageHelper'
import { KEY_TOKEN, KEY_USER_INFO, KEY_CURRENT_TAB } from '../common/Constants'
import { KEY_DB_READY } from '../common/Constants'
import { TabIndex } from '../common/Enums'

/**
 * 启动页
 * 展示入场动画，检测登录状态后自动跳转
 * - 已登录：跳转 MainPage
 * - 未登录：跳转 LoginPage
 */
@Entry
@Component
struct SplashPage {
  @State scaleValue: number = 0.3
  @State opacityValue: number = 0
  @State subtitleOpacity: number = 0
  @State progressValue: number = 0

  aboutToAppear(): void {
    // PersistentStorage.persistProp 已在 EntryAbility.onCreate 中完成初始化
    // 此处确保有默认值
    const savedToken: string = StorageHelper.get<string>(KEY_TOKEN) ?? ''
    if (savedToken === '') {
      StorageHelper.set(KEY_TOKEN, '')
    }

    // 入场动画 - 缩放 + 淡入
    animateTo({
      duration: 800,
      curve: Curve.EaseOut
    }, () => {
      this.scaleValue = 1
      this.opacityValue = 1
    })

    // 副标题延迟淡入
    setTimeout(() => {
      animateTo({
        duration: 500,
        curve: Curve.EaseIn
      }, () => {
        this.subtitleOpacity = 1
      })
    }, 400)

    // 模拟加载进度
    this.simulateProgress()

    // 2.5 秒后跳转
    setTimeout(() => {
      this.navigateToNext()
    }, 2500)
  }

  /**
   * 模拟加载进度条动画
   */
  simulateProgress(): void {
    let step = 0
    const totalSteps = 20
    const interval = setInterval(() => {
      step++
      this.progressValue = step / totalSteps * 100
      if (step >= totalSteps) {
        clearInterval(interval)
      }
    }, 75)
  }

  /**
   * 根据登录状态导航到对应页面
   */
  navigateToNext(): void {
    // 等待数据库初始化完成
    const dbReady: boolean = StorageHelper.get<boolean>(KEY_DB_READY) ?? false
    if (!dbReady) {
      // 每 200ms 检查一次，最多等待 10 秒
      const maxRetry = 50
      let retryCount = 0
      const checkDbReady = setInterval(() => {
        retryCount++
        const currentDbReady: boolean = StorageHelper.get<boolean>(KEY_DB_READY) ?? false
        if (currentDbReady || retryCount >= maxRetry) {
          clearInterval(checkDbReady)
          this.doNavigate()
        }
      }, 200)
    } else {
      this.doNavigate()
    }
  }

  doNavigate(): void {
    const token: string = StorageHelper.get<string>(KEY_TOKEN) ?? ''
    if (token.length > 0) {
      router.replaceUrl({ url: 'pages/MainPage' })
    } else {
      router.replaceUrl({ url: 'pages/LoginPage' })
    }
  }

  build() {
    Column() {
      Column() {
        // Logo 区域
        Text('诗')
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A90D9')
          .fontFamily('serif')

        Blank().height(16)

        Text('诗词学习')
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Blank().height(8)

        Text('品味经典，传承文化')
          .fontSize(14)
          .fontColor('#999999')
          .opacity(this.subtitleOpacity)
      }
      .scale({ x: this.scaleValue, y: this.scaleValue })
      .opacity(this.opacityValue)

      // 底部加载进度
      Blank().height(60)

      Column() {
        Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
          .width(120)
          .height(2)
          .color('#4A90D9')
          .backgroundColor('#F0F0F0')

        Blank().height(8)

        Text('正在加载诗词数据...')
          .fontSize(12)
          .fontColor('#CCCCCC')
      }
      .opacity(this.subtitleOpacity)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FAF8F5')
  }
}

