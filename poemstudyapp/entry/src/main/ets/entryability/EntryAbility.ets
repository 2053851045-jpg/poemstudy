import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { window } from '@kit.ArkUI'
import { resourceManager } from '@kit.LocalizationKit'
import { StorageHelper } from '../utils/StorageHelper'
import { util } from '@kit.ArkTS'
import { DatabaseHelper } from '../model/DatabaseHelper'
import { KEY_DB_READY, KEY_TOKEN, KEY_USER_ID, KEY_USER_INFO, KEY_CURRENT_TAB } from '../common/Constants'
import { Poem } from '../common/Types'

const DOMAIN = 0x0000
const TAG = 'EntryAbility'

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err))
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate')

    // 初始化 preferences 持久化存储（恢复上次登录态）
    await StorageHelper.init(this.context)

    // 仅首次启动时设置默认值，不覆盖已有持久化数据
    if (!StorageHelper.has(KEY_TOKEN)) {
      StorageHelper.set(KEY_TOKEN, '')
    }
    if (!StorageHelper.has(KEY_USER_INFO)) {
      StorageHelper.set(KEY_USER_INFO, '')
    }
    if (!StorageHelper.has(KEY_CURRENT_TAB)) {
      StorageHelper.set(KEY_CURRENT_TAB, 0)
    }
    if (!StorageHelper.has(KEY_USER_ID)) {
      // 首次安装生成持久化用户 ID
      const uid = Math.abs(Math.floor(Math.random() * 9999999)) || 1
      StorageHelper.set(KEY_USER_ID, uid)
      hilog.info(DOMAIN, TAG, `生成持久化用户 ID: ${uid}`)
    }

    // 初始化数据库
    await this.initDatabase()
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate')

    windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err))
        return
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.')
    })
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy')
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground')
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground')
  }

  /**
   * 初始化数据库并导入种子数据
   */
  private async initDatabase(): Promise<void> {
    try {
      const dbHelper = DatabaseHelper.getInstance()
      await dbHelper.init(this.context)
      hilog.info(DOMAIN, TAG, '数据库初始化成功')

      // 检查是否需要导入种子数据
      const hasData = await dbHelper.hasSeedData()
      if (!hasData) {
        hilog.info(DOMAIN, TAG, '开始导入种子数据...')
        await this.loadSeedData(dbHelper)
      } else {
        hilog.info(DOMAIN, TAG, '种子数据已存在，跳过导入')
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '数据库初始化失败: %{public}s', JSON.stringify(err))
    }
    // 通知各页面数据库已准备就绪
    StorageHelper.set(KEY_DB_READY, true)
  }

  /**
   * 从 rawfile 读取 poems.json 并批量插入
   */
  private async loadSeedData(dbHelper: DatabaseHelper): Promise<void> {
    try {
      const resMgr: resourceManager.ResourceManager = this.context.resourceManager
      const rawFileData = await resMgr.getRawFileContent('poems.json')
      const decoder = new util.TextDecoder('utf-8')
      const jsonStr = decoder.decodeWithStream(rawFileData, { stream: false })
      const poems: Poem[] = JSON.parse(jsonStr) as Poem[]

      if (!Array.isArray(poems) || poems.length === 0) {
        hilog.warn(DOMAIN, TAG, 'poems.json 内容为空或格式不正确')
        return
      }

      const insertedCount = await dbHelper.insertSeedPoems(poems)
      hilog.info(DOMAIN, TAG, `种子数据导入完成，共 ${insertedCount} 条`)
    } catch (err) {
      hilog.error(DOMAIN, TAG, '种子数据加载失败: %{public}s', JSON.stringify(err))
    }
  }
}
