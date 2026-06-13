import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'

const PREF_NAME = 'poemstudy_prefs'

/**
 * 全局键值存储工具（基于 @ohos.data.preferences 持久化）
 * 替代 @kit.ArkUI 的 AppStorage/PersistentStorage
 *
 * 模式：内存 cache Map（同步读）+ preferences 异步持久化
 * - 所有 get() 调用同步从缓存读取，不阻塞 UI
 * - 所有 set() 同步写缓存 + 异步写磁盘
 *
 * 考点：preferences 持久化存储（替代 AppStorage）
 */
export class StorageHelper {
  private static prefs: preferences.Preferences | null = null
  private static store: Map<string, Object> = new Map()

  /**
   * 初始化（在 EntryAbility.onCreate 中调用一次）
   * 从 preferences 加载所有已持久化数据到内存缓存
   */
  static async init(context: common.UIAbilityContext): Promise<void> {
    try {
      StorageHelper.prefs = await preferences.getPreferences(context, PREF_NAME)
      // 加载持久化键到内存缓存
      // token
      const token = await StorageHelper.prefs.get('token', '')
      if (token !== '' && token !== undefined) {
        StorageHelper.store.set('token', token)
      }
      // userInfo
      const userInfo = await StorageHelper.prefs.get('userInfo', '')
      if (userInfo !== '' && userInfo !== undefined) {
        StorageHelper.store.set('userInfo', userInfo)
      }
      // currentTab
      const currentTab = await StorageHelper.prefs.get('currentTab', -1)
      if (currentTab !== -1 && currentTab !== undefined) {
        StorageHelper.store.set('currentTab', currentTab)
      }
      // userId
      const userId = await StorageHelper.prefs.get('userId', -1)
      if (userId !== -1 && userId !== undefined) {
        StorageHelper.store.set('userId', userId)
      }
      console.info('StorageHelper', '初始化完成，已加载持久化数据')
    } catch (err) {
      console.error('StorageHelper', '初始化失败: ' + JSON.stringify(err))
    }
  }

  /**
   * 同步获取值
   */
  static get<T>(key: string): T | undefined {
    return StorageHelper.store.get(key) as T | undefined
  }

  /**
   * 设置值（同步写缓存 + 异步持久化）
   */
  static set(key: string, value: Object): void {
    StorageHelper.store.set(key, value)
    if (StorageHelper.prefs) {
      StorageHelper.prefs.put(key, value)
      StorageHelper.prefs.flush()
    }
  }

  /**
   * 检查键是否存在
   */
  static has(key: string): boolean {
    return StorageHelper.store.has(key)
  }

  /**
   * 删除键
   */
  static delete(key: string): void {
    StorageHelper.store.delete(key)
    if (StorageHelper.prefs) {
      StorageHelper.prefs.delete(key)
      StorageHelper.prefs.flush()
    }
  }
}
