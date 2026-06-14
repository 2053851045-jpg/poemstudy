import { router } from '@kit.ArkUI'
import { StorageHelper } from '../utils/StorageHelper'
import { DatabaseHelper } from '../model/DatabaseHelper'
import { KEY_TOKEN, KEY_USER_INFO, KEY_USER_ID } from '../common/Constants'

/**
 * 登录页面 — 三模式：登录 / 注册 / 游客
 *
 * 考点：
 * - 表单校验（TextInput + 条件渲染）
 * - axios POST 登录（通过 ApiService）
 * - router.replaceUrl
 * - 数据库用户管理（registerUser / verifyLogin）
 * - 游客数据隔离 + 退出清理
 */
@Entry
@Component
struct LoginPage {
  @State currentTab: number = 0
  @State isLoading: boolean = false
  @State errorMsg: string = ''

  // 登录表单
  @State loginUsername: string = ''
  @State loginPassword: string = ''

  // 注册表单
  @State regUsername: string = ''
  @State regPassword: string = ''
  @State regConfirm: string = ''
  @State regNickname: string = ''

  private tabLabels: string[] = ['登录', '注册', '游客']
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()

  aboutToAppear(): void {
    const savedToken: string = StorageHelper.get<string>(KEY_TOKEN) ?? ''
    if (savedToken && savedToken.length > 0) {
      router.replaceUrl({ url: 'pages/MainPage' })
    }
  }

  build() {
    Column() {
      // 品牌区
      Column() {
        Text('诗')
          .fontSize(52)
          .fontWeight(FontWeight.Bold)
          .fontColor('#3A3A3A')
          .fontFamily('serif')
        Blank().height(6)
        Text('诗词学习')
          .fontSize(20)
          .fontColor('#4A4A4A')
        Blank().height(4)
        Text('品味经典 · 传承文化')
          .fontSize(12)
          .fontColor('#8B7355')
      }
      .margin({ top: 60 })
      .alignItems(HorizontalAlign.Center)

      Blank().height(32)

      // Tab 切换
      Row() {
        ForEach(this.tabLabels, (label: string, index: number) => {
          Column() {
            Text(label)
              .fontSize(16)
              .fontColor(this.currentTab === index ? '#8B4513' : '#B8A898')
              .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal)
              .padding({ bottom: 6 })
            Divider()
              .strokeWidth(2)
              .color(this.currentTab === index ? '#8B4513' : 'transparent')
              .width(40)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { this.currentTab = index; this.errorMsg = '' })
        })
      }
      .width('80%')
      .margin({ bottom: 24 })

      Scroll() {
        Column() {
          if (this.currentTab === 0) {
            this.loginForm()
          } else if (this.currentTab === 1) {
            this.registerForm()
          } else {
            this.guestForm()
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 40 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAF8F5')
    .alignItems(HorizontalAlign.Center)
  }

  // ==================== 登录表单 ====================

  @Builder
  loginForm() {
    Column() {
      TextInput({ placeholder: '用户名', text: this.loginUsername })
        .width('85%').height(48).fontSize(15)
        .backgroundColor('#F5F0E8').borderRadius(8)
        .padding({ left: 16 })
        .onChange((v: string) => { this.loginUsername = v; this.errorMsg = '' })

      Blank().height(16)

      TextInput({ placeholder: '密码', text: this.loginPassword })
        .width('85%').height(48).fontSize(15)
        .backgroundColor('#F5F0E8').borderRadius(8)
        .padding({ left: 16 })
        .type(InputType.Password)
        .onChange((v: string) => { this.loginPassword = v; this.errorMsg = '' })

      if (this.errorMsg) {
        Text(this.errorMsg)
          .fontSize(13).fontColor('#CC3333').margin({ top: 10 })
      }

      Blank().height(24)

      Button(this.isLoading ? '登录中...' : '登 录')
        .width('85%').height(48).fontSize(17)
        .fontColor('#FFFFFF').backgroundColor('#8B4513')
        .borderRadius(24)
        .enabled(this.loginUsername.length > 0 && this.loginPassword.length > 0 && !this.isLoading)
        .onClick(() => { this.doLogin() })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  async doLogin(): Promise<void> {
    if (!this.loginUsername || !this.loginPassword) {
      this.errorMsg = '请输入用户名和密码'
      return
    }
    this.isLoading = true
    this.errorMsg = ''
    try {
      const user = await this.dbHelper.verifyLogin(this.loginUsername, this.loginPassword)
      if (user) {
        StorageHelper.set(KEY_TOKEN, 'user_token_' + user.id)
        StorageHelper.set(KEY_USER_INFO, JSON.stringify({ nickname: user.nickname, avatar: user.avatar, role: 'registered' }))
        StorageHelper.set(KEY_USER_ID, user.id)
        router.replaceUrl({ url: 'pages/MainPage' })
      } else {
        this.errorMsg = '用户名或密码错误'
      }
    } catch (err) {
      this.errorMsg = '网络异常，请重试'
    } finally {
      this.isLoading = false
    }
  }

  // ==================== 注册表单 ====================

  @Builder
  registerForm() {
    Column() {
      TextInput({ placeholder: '用户名（用于登录）', text: this.regUsername })
        .width('85%').height(48).fontSize(15)
        .backgroundColor('#F5F0E8').borderRadius(8)
        .padding({ left: 16 })
        .onChange((v: string) => { this.regUsername = v; this.errorMsg = '' })

      Blank().height(12)

      TextInput({ placeholder: '昵称（显示在打卡圈）', text: this.regNickname })
        .width('85%').height(48).fontSize(15)
        .backgroundColor('#F5F0E8').borderRadius(8)
        .padding({ left: 16 })
        .onChange((v: string) => { this.regNickname = v })

      Blank().height(12)

      TextInput({ placeholder: '密码', text: this.regPassword })
        .width('85%').height(48).fontSize(15)
        .backgroundColor('#F5F0E8').borderRadius(8)
        .padding({ left: 16 })
        .type(InputType.Password)
        .onChange((v: string) => { this.regPassword = v; this.errorMsg = '' })

      Blank().height(12)

      TextInput({ placeholder: '确认密码', text: this.regConfirm })
        .width('85%').height(48).fontSize(15)
        .backgroundColor('#F5F0E8').borderRadius(8)
        .padding({ left: 16 })
        .type(InputType.Password)
        .onChange((v: string) => { this.regConfirm = v; this.errorMsg = '' })

      Blank().height(12)

      Text('提示：注册后自动登录，数据永久保存')
        .fontSize(12)
        .fontColor('#8B7355')

      if (this.errorMsg) {
        Text(this.errorMsg)
          .fontSize(13).fontColor('#CC3333').margin({ top: 10 })
      }

      Blank().height(24)

      Button(this.isLoading ? '注册中...' : '注 册')
        .width('85%').height(48).fontSize(17)
        .fontColor('#FFFFFF').backgroundColor('#5B8C5A')
        .borderRadius(24)
        .enabled(this.regUsername.length > 0 && this.regPassword.length > 0 && !this.isLoading)
        .onClick(() => { this.doRegister() })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  async doRegister(): Promise<void> {
    if (!this.regUsername || !this.regPassword) {
      this.errorMsg = '请填写用户名和密码'
      return
    }
    if (this.regPassword !== this.regConfirm) {
      this.errorMsg = '两次密码输入不一致'
      return
    }
    if (this.regUsername.length < 3) {
      this.errorMsg = '用户名至少3个字符'
      return
    }
    this.isLoading = true
    this.errorMsg = ''
    try {
      // 检查用户名是否已存在
      const existing = await this.dbHelper.findUserByUsername(this.regUsername)
      if (existing) {
        this.errorMsg = '该用户名已被注册'
        this.isLoading = false
        return
      }
      // 创建新用户
      const nickname = this.regNickname.trim() || this.regUsername
      const userId = await this.dbHelper.registerUser(this.regUsername, this.regPassword, nickname)
      // 自动登录
      StorageHelper.set(KEY_TOKEN, 'user_token_' + userId)
      StorageHelper.set(KEY_USER_INFO, JSON.stringify({ nickname: nickname, avatar: '', role: 'registered' }))
      StorageHelper.set(KEY_USER_ID, userId)
      router.replaceUrl({ url: 'pages/MainPage' })
    } catch (err) {
      this.errorMsg = '注册失败，用户名可能已存在'
    } finally {
      this.isLoading = false
    }
  }

  // ==================== 游客模式 ====================

  @Builder
  guestForm() {
    Column() {
      Text('🍃')
        .fontSize(48)
        .margin({ bottom: 12 })

      Text('以游客身份浏览')
        .fontSize(17)
        .fontColor('#3A3A3A')
        .fontWeight(FontWeight.Medium)

      Blank().height(8)

      Text('您的数据仅在本次使用，退出后自动清理')
        .fontSize(13)
        .fontColor('#8B7355')
        .textAlign(TextAlign.Center)
        .width('70%')

      Blank().height(32)

      Button('进入体验')
        .width('60%').height(48).fontSize(17)
        .fontColor('#FFFFFF').backgroundColor('#8B7355')
        .borderRadius(24)
        .onClick(() => { this.doGuest() })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  doGuest(): void {
    const guestId = -(Date.now())
    StorageHelper.set(KEY_TOKEN, 'guest_token_' + guestId)
    StorageHelper.set(KEY_USER_INFO, JSON.stringify({ nickname: '游客', avatar: '', role: 'guest' }))
    StorageHelper.set(KEY_USER_ID, guestId)
    router.replaceUrl({ url: 'pages/MainPage' })
  }
}
