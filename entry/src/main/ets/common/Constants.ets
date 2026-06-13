/**
 * 数据库配置
 */
export const DB_NAME = 'poemstudy.db'
export const DB_PASSWORD = '123456'

/**
 * 数据库表名
 */
export const TABLE_POEM = 'poem'
export const TABLE_FAVORITE = 'favorite'
export const TABLE_QUIZ_RECORD = 'quiz_record'

/**
 * API 配置
 */
export const BASE_URL = 'http://localhost:3000/api'
export const REQUEST_TIMEOUT = 10000

/**
 * 持久化 Key
 */
export const KEY_TOKEN = 'token'
export const KEY_USER_INFO = 'userInfo'
export const KEY_CURRENT_TAB = 'currentTab'

/** DB 初始完成标志 */
export const KEY_DB_READY = 'dbReady'

/**
 * 分页
 */
export const PAGE_SIZE = 20

/**
 * 测验配置
 */
export const QUIZ_QUESTION_COUNT = 5
export const QUIZ_TIME_LIMIT = 60 // 秒

/**
 * 颜色常量（对应 color.json 中的资源定义）
 * 用于 @State 等编程式颜色引用；UI 构建中优先使用 $r('app.color.xxx')
 */

