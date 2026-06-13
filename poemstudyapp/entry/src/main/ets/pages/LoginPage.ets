import { router } from '@kit.ArkUI'
import { StorageHelper } from '../utils/StorageHelper'
import { ApiService } from '../services/ApiService'
import { KEY_TOKEN, KEY_USER_INFO, KEY_USER_ID } from '../common/Constants'

/**
 * 登录页面
 * 支持在线登录和离线体验两种模式
 * 在线模式：调用后端登录接口获取 Token
 * 离线模式：本地生成模拟数据，直接进入应用
 */
@Entry
@Component
struct LoginPage {
  @State nickname: string = ''
  @State isLoading: boolean = false
  @State errorMsg: string = ''
  @State offlineHint: boolean = false

  aboutToAppear(): void {
    // persistProp 已在 SplashPage 中完成，此处只确保有默认值
  }

  /**
   * 校验昵称合法性
   * @returns 错误信息，空字符串表示通过
   */
  validateNickname(): string {
    const name = this.nickname.trim()
    if (!name) return '请输入昵称'
    if (name.length < 2) return '昵称至少需要2个字符'
    if (name.length > 12) return '昵称最多12个字符'
    if (!/^[\u4e00-\u9fa5a-zA-Z0-9_]+$/.test(name)) return '昵称只能包含中文、字母、数字和下划线'
    return ''
  }

  build() {
    Column() {
      // 顶部装饰
      Column() {
        Text('诗')
          .fontSize(52)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A90D9')
          .fontFamily('serif')

        Blank().height(8)

        Text('欢迎来到诗词学习')
          .fontSize(18)
          .fontColor('#333333')

        Blank().height(4)

        Text('品味经典，传承文化')
          .fontSize(13)
          .fontColor('#999999')
      }
      .margin({ top: 100 })

      Blank().height(60)

      // 输入区域
      Column() {
        TextInput({ placeholder: '请输入您的昵称', text: this.nickname })
          .width('80%')
          .height(48)
          .fontSize(16)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 16, right: 16 })
          .maxLength(12)
          .onChange((value: string) => {
            this.nickname = value
            this.errorMsg = ''
          })
          .onSubmit(() => {
            this.handleLogin()
          })

        if (this.errorMsg) {
          Text(this.errorMsg)
            .fontSize(13)
            .fontColor('#E74C3C')
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Blank().height(40)

      // 登录按钮
      Button(this.isLoading ? '登录中...' : '进入应用')
        .width('80%')
        .height(48)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(this.nickname.trim().length >= 2 ? '#4A90D9' : '#CCCCCC')
        .borderRadius(24)
        .enabled(this.nickname.trim().length >= 2 && !this.isLoading)
        .onClick(() => {
          this.handleLogin()
        })

      Blank().height(20)

      // 直接进入（离线模式）
      Button('离线体验')
        .width('80%')
        .height(48)
        .fontSize(16)
        .fontColor('#4A90D9')
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#4A90D9' })
        .borderRadius(24)
        .onClick(() => {
          this.offlineEnter()
        })

      Blank().height(40)

      // 版本信息
      Text('v1.0.0')
        .fontSize(12)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  /**
   * 处理登录逻辑
   *
   * 流程：
   * 1. 校验昵称合法性
   * 2. 调用后端登录接口获取 Token 和用户信息
   * 3. 持久化存储 Token 和用户信息
   * 4. 成功后跳转 MainPage
   * 5. 网络失败时自动降级为离线模式
   */
  async handleLogin(): Promise<void> {
    const name = this.nickname.trim()
    const error = this.validateNickname()
    if (error) {
      this.errorMsg = error
      return
    }

    this.isLoading = true
    this.errorMsg = ''

    try {
      const api = ApiService.getInstance()
      const res = await api.login(name)

      if (res.code === 0 && res.data) {
        // 持久化存储登录凭证
        StorageHelper.set(KEY_TOKEN, res.data.token)
        StorageHelper.set(KEY_USER_INFO, JSON.stringify(res.data.userInfo))
        StorageHelper.set(KEY_USER_ID, this.deriveUserId(name))
        console.info('LoginPage', `用户 ${name} 登录成功`)
        router.replaceUrl({ url: 'pages/MainPage' })
      } else {
        // 后端返回非0错误码，提示用户后进入离线模式
        console.warn('LoginPage', `登录接口返回异常 code=${res.code}`)
        this.errorMsg = '服务器繁忙，已切换至离线模式'
        setTimeout(() => { this.offlineEnter() }, 800)
      }
    } catch (err) {
      // 网络异常自动降级：直接以离线模式进入应用
      console.error('LoginPage', '登录请求失败，使用离线模式')
      this.offlineEnter()
    } finally {
      this.isLoading = false
    }
  }

  /**
   * 离线模式进入（跳过网络请求，本地生成模拟身份）
   *
   * 适用场景：
   * - 网络不可用时
   * - 后端服务异常时
   * - 用户选择"离线体验"
   */
  offlineEnter(): void {
    const name = this.nickname.trim() || '诗词爱好者'
    StorageHelper.set(KEY_TOKEN, 'offline_token_' + Date.now())
    StorageHelper.set(KEY_USER_INFO, '{"nickname":"' + name + '","avatar":"","level":1,"joinDate":"' + new Date().toISOString().split('T')[0] + '"}')
    StorageHelper.set(KEY_USER_ID, this.deriveUserId(name))
    console.info('LoginPage', `离线模式进入，用户: ${name}`)
    router.replaceUrl({ url: 'pages/MainPage' })
  }

  /**
   * 基于昵称哈希生成稳定的用户 ID
   * 相同昵称始终获得相同 ID，实现用户数据隔离
   */
  private deriveUserId(nickname: string): number {
    let hash = 0
    for (let i = 0; i < nickname.length; i++) {
      const char = nickname.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash
    }
    return Math.abs(hash) || 1
  }
}