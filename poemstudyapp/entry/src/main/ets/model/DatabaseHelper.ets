
import relationalStore from '@ohos.data.relationalStore'
import { common } from '@kit.AbilityKit'
import { StorageHelper } from '../utils/StorageHelper'
import { DB_NAME, TABLE_POEM, TABLE_FAVORITE, TABLE_QUIZ_RECORD, TABLE_CHECKIN, KEY_USER_ID } from '../common/Constants'
import { Poem, Favorite, QuizRecord, DynastyStat, CategoryStat, CheckInRecord } from '../common/Types'

const TAG = 'DatabaseHelper'

// ==================== 建表 SQL ====================
const SQL_CREATE_POEM = `
  CREATE TABLE IF NOT EXISTS ${TABLE_POEM} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    author TEXT,
    dynasty TEXT,
    content TEXT NOT NULL,
    category TEXT,
    image_id TEXT
  )
`

const SQL_CREATE_FAVORITE = `
  CREATE TABLE IF NOT EXISTS ${TABLE_FAVORITE} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER DEFAULT 1,
    poem_id INTEGER NOT NULL,
    create_time TEXT,
    FOREIGN KEY (poem_id) REFERENCES ${TABLE_POEM}(id) ON DELETE CASCADE
  )
`


const SQL_CREATE_CHECKIN = `
  CREATE TABLE IF NOT EXISTS ${TABLE_CHECKIN} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    checkin_date TEXT NOT NULL,
    poem_title TEXT,
    content TEXT,
    create_time TEXT
  )
`
const SQL_CREATE_QUIZ_RECORD = `
  CREATE TABLE IF NOT EXISTS ${TABLE_QUIZ_RECORD} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER DEFAULT 1,
    poem_id INTEGER,
    score INTEGER,
    quiz_time TEXT
  )
`

// 索引 SQL
const SQL_INDEX_POEM_TITLE = `CREATE INDEX IF NOT EXISTS idx_poem_title ON ${TABLE_POEM}(title)`
const SQL_INDEX_POEM_CATEGORY = `CREATE INDEX IF NOT EXISTS idx_poem_category ON ${TABLE_POEM}(category)`
const SQL_INDEX_FAVORITE = `CREATE UNIQUE INDEX IF NOT EXISTS idx_favorite_user_poem ON ${TABLE_FAVORITE}(user_id, poem_id)`
const SQL_INDEX_QUIZ = `CREATE INDEX IF NOT EXISTS idx_quiz_user_time ON ${TABLE_QUIZ_RECORD}(user_id, quiz_time)`
const SQL_INDEX_CHECKIN = `CREATE UNIQUE INDEX IF NOT EXISTS idx_checkin_user_date ON ${TABLE_CHECKIN}(user_id, checkin_date)`

/**
 * 数据库管理单例类
 *
 * 负责：
 * - 数据库创建与表结构初始化（3张表：poem、favorite、quiz_record）
 * - 诗词数据的CRUD及搜索/筛选
 * - 收藏管理（添加/删除/查询）
 * - 测验记录存储与查询
 * - 聚合统计（按朝代、分类统计数量）
 * - 种子数据导入（从 rawfile 读取 poems.json 批量插入）
 *
 * 使用方式：
 *   const dbHelper = DatabaseHelper.getInstance()
 *   const poems = await dbHelper.queryPoems('唐诗', '静夜思', 20, 0)
 */
export class DatabaseHelper {
  private static instance: DatabaseHelper
  private rdbStore: relationalStore.RdbStore | null = null
  private context: common.UIAbilityContext | null = null

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper()
    }
    return DatabaseHelper.instance
  }

  /**
   * 初始化数据库（在 EntryAbility.onCreate 中调用）
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context
    const storeConfig: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, storeConfig)
      console.info(TAG, '数据库打开成功')
      await this.createTables()
    } catch (err) {
      console.error(TAG, '数据库初始化失败: %{public}s', JSON.stringify(err))
      throw err instanceof Error ? err : new Error()
    }
  }

  /**
   * 建表 + 创建索引
   */
  private async createTables(): Promise<void> {
    if (!this.rdbStore) return
    try {
      await this.rdbStore.executeSql(SQL_CREATE_POEM)
      await this.rdbStore.executeSql(SQL_CREATE_FAVORITE)
      await this.rdbStore.executeSql(SQL_CREATE_QUIZ_RECORD)
      await this.rdbStore.executeSql(SQL_CREATE_CHECKIN)
      await this.rdbStore.executeSql(SQL_INDEX_POEM_TITLE)
      await this.rdbStore.executeSql(SQL_INDEX_POEM_CATEGORY)
      await this.rdbStore.executeSql(SQL_INDEX_FAVORITE)
      await this.rdbStore.executeSql(SQL_INDEX_QUIZ)
      await this.rdbStore.executeSql(SQL_INDEX_CHECKIN)
      console.info(TAG, '建表成功')
    } catch (err) {
      console.error(TAG, '建表失败: %{public}s', JSON.stringify(err))
      throw err instanceof Error ? err : new Error()
    }
  }

  /**
   * 获取 RdbStore 实例
   */
  getStore(): relationalStore.RdbStore | null {
    return this.rdbStore
  }

  // ==================== 种子数据导入 ====================

  /**
   * 检查 poem 表是否已有数据
   */
  async hasSeedData(): Promise<boolean> {
    if (!this.rdbStore) return false
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const sql = `SELECT COUNT(*) AS cnt FROM ${TABLE_POEM}`
      resultSet = await this.rdbStore.querySql(sql)
      if (resultSet.goToFirstRow()) {
        const count = resultSet.getLong(resultSet.getColumnIndex('cnt'))
        return count >= 300
      }
      return false
    } catch (err) {
      console.error(TAG, '检查种子数据失败: %{public}s', JSON.stringify(err))
      return false
    } finally {
      resultSet?.close()
    }
  }

  /**
   * 批量导入种子数据（JSON 数组）
   */
  async insertSeedPoems(poems: Poem[]): Promise<number> {
    if (!this.rdbStore) throw new Error('数据库未初始化')
    if (poems.length === 0) return 0

    let insertedCount = 0
    try {
      this.rdbStore.beginTransaction()
      for (const poem of poems) {
        const valueBucket: relationalStore.ValuesBucket = {
          'title': poem.title,
          'author': poem.author,
          'dynasty': poem.dynasty,
          'content': poem.content,
          'category': poem.category,
          'image_id': poem.imageId
        }
        await this.rdbStore.insert(TABLE_POEM, valueBucket)
        insertedCount++
      }
      this.rdbStore.commit()
      console.info(TAG, `种子数据导入完成，共 ${insertedCount} 条`)
    } catch (err) {
      this.rdbStore.rollBack()
      console.error(TAG, '种子数据导入失败: %{public}s', JSON.stringify(err))
      throw err instanceof Error ? err : new Error()
    }
    return insertedCount
  }

  // ==================== Poem 表 CRUD ====================

  /**
   * 分页查询诗词列表
   */
  async queryPoems(
    category?: string,
    keyword?: string,
    limit: number = 20,
    offset: number = 0
  ): Promise<Poem[]> {
    if (!this.rdbStore) return []
    let resultSet: relationalStore.ResultSet | null = null
    const result: Poem[] = []
    try {
      let predicates = new relationalStore.RdbPredicates(TABLE_POEM)
      if (category != null && category.length > 0) {
        predicates.equalTo('category', category)
      }
      if (keyword != null && keyword.length > 0) {
        predicates.beginWrap()
        predicates.like('title', `%${keyword}%`)
        predicates.or()
        predicates.like('author', `%${keyword}%`)
        predicates.or()
        predicates.like('content', `%${keyword}%`)
        predicates.endWrap()
      }
      predicates.orderByAsc('id')
      predicates.limitAs(limit)
      predicates.offsetAs(offset)

      resultSet = await this.rdbStore.query(predicates)
      while (resultSet.goToNextRow()) {
        result.push(this.rowToPoem(resultSet))
      }
    } catch (err) {
      console.error(TAG, '查询诗词列表失败: %{public}s', JSON.stringify(err))
    } finally {
      resultSet?.close()
    }
    return result
  }

  /**
   * 根据 ID 查询单条诗词
   */
  async getPoemById(id: number): Promise<Poem | null> {
    if (!this.rdbStore) return null
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_POEM)
        .equalTo('id', id)
      resultSet = await this.rdbStore.query(predicates)
      if (resultSet.goToFirstRow()) {
        return this.rowToPoem(resultSet)
      }
    } catch (err) {
      console.error(TAG, '查询诗词详情失败: %{public}s', JSON.stringify(err))
    } finally {
      resultSet?.close()
    }
    return null
  }

  /**
   * 获取诗词总数（用于分页）
   */
  async getPoemCount(category?: string, keyword?: string): Promise<number> {
    if (!this.rdbStore) return 0
    let resultSet: relationalStore.ResultSet | null = null
    try {
      let sql = `SELECT COUNT(*) AS cnt FROM ${TABLE_POEM}`
      const conditions: string[] = []
      if (category != null && category.length > 0) {
        conditions.push(`category = '${category.replace(/'/g, "''")}'`)
      }
      if (keyword != null && keyword.length > 0) {
        conditions.push(`title LIKE '%${keyword.replace(/'/g, "''")}%'`)
      }
      if (conditions.length > 0) {
        sql += ' WHERE ' + conditions.join(' AND ')
      }
      resultSet = await this.rdbStore.querySql(sql)
      if (resultSet.goToFirstRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('cnt'))
      }
      return 0
    } catch (err) {
      console.error(TAG, '查询诗词总数失败: %{public}s', JSON.stringify(err))
      return 0
    } finally {
      resultSet?.close()
    }
  }

  /**
   * 随机抽取 N 条诗词（用于测验）
   */
  async getRandomPoems(count: number = 5): Promise<Poem[]> {
    if (!this.rdbStore) return []
    let resultSet: relationalStore.ResultSet | null = null
    const result: Poem[] = []
    try {
      const sql = `SELECT * FROM ${TABLE_POEM} ORDER BY RANDOM() LIMIT ${count}`
      resultSet = await this.rdbStore.querySql(sql)
      while (resultSet.goToNextRow()) {
        result.push(this.rowToPoem(resultSet))
      }
    } catch (err) {
      console.error(TAG, '随机抽取诗词失败: %{public}s', JSON.stringify(err))
    } finally {
      resultSet?.close()
    }
    return result
  }

  // ==================== Favorite 表操作 ====================

  /**
   * 添加收藏
   */
  async addFavorite(poemId: number): Promise<boolean> {
    if (!this.rdbStore) return false
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'user_id': this.getCurrentUserId(),
        'poem_id': poemId,
        'create_time': this.getNowStr()
      }
      await this.rdbStore.insert(TABLE_FAVORITE, valueBucket)
      return true
    } catch (err) {
      console.error(TAG, '添加收藏失败: %{public}s', JSON.stringify(err))
      return false
    }
  }

  /**
   * 取消收藏
   */
  async removeFavorite(poemId: number): Promise<boolean> {
    if (!this.rdbStore) return false
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_FAVORITE)
        .equalTo('user_id', this.getCurrentUserId())
        .equalTo('poem_id', poemId)
      const rows = await this.rdbStore.delete(predicates)
      return rows > 0
    } catch (err) {
      console.error(TAG, '取消收藏失败: %{public}s', JSON.stringify(err))
      return false
    }
  }

  /**
   * 检查是否已收藏
   */
  async isFavorited(poemId: number): Promise<boolean> {
    if (!this.rdbStore) return false
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_FAVORITE)
        .equalTo('user_id', this.getCurrentUserId())
        .equalTo('poem_id', poemId)
      resultSet = await this.rdbStore.query(predicates)
      return resultSet.rowCount > 0
    } catch (err) {
      console.error(TAG, '检查收藏状态失败: %{public}s', JSON.stringify(err))
      return false
    } finally {
      resultSet?.close()
    }
  }

  /**
   * 获取收藏列表（联查 poem 表）
   */
  async queryFavorites(limit: number = 50, offset: number = 0): Promise<Poem[]> {
    if (!this.rdbStore) return []
    let resultSet: relationalStore.ResultSet | null = null
    const result: Poem[] = []
    try {
      const sql = `
        SELECT p.* FROM ${TABLE_POEM} p
        INNER JOIN ${TABLE_FAVORITE} f ON p.id = f.poem_id
        WHERE f.user_id = ${this.getCurrentUserId()}
        ORDER BY f.create_time DESC
        LIMIT ${limit} OFFSET ${offset}
      `
      resultSet = await this.rdbStore.querySql(sql)
      while (resultSet.goToNextRow()) {
        result.push(this.rowToPoem(resultSet))
      }
    } catch (err) {
      console.error(TAG, '查询收藏列表失败: %{public}s', JSON.stringify(err))
    } finally {
      resultSet?.close()
    }
    return result
  }

  /**
   * 获取收藏总数
   */
  async getFavoriteCount(): Promise<number> {
    if (!this.rdbStore) return 0
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const sql = `SELECT COUNT(*) AS cnt FROM ${TABLE_FAVORITE} WHERE user_id = ${this.getCurrentUserId()}`
      resultSet = await this.rdbStore.querySql(sql)
      if (resultSet.goToFirstRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('cnt'))
      }
      return 0
    } catch (err) {
      console.error(TAG, '查询收藏总数失败: %{public}s', JSON.stringify(err))
      return 0
    } finally {
      resultSet?.close()
    }
  }

  // ==================== QuizRecord 表操作 ====================

  /**
   * 添加测验记录
   */
  async addQuizRecord(poemId: number, score: number): Promise<boolean> {
    if (!this.rdbStore) return false
    try {
      const valueBucket: relationalStore.ValuesBucket = {
        'user_id': this.getCurrentUserId(),
        'poem_id': poemId,
        'score': score,
        'quiz_time': this.getNowStr()
      }
      await this.rdbStore.insert(TABLE_QUIZ_RECORD, valueBucket)
      return true
    } catch (err) {
      console.error(TAG, '添加测验记录失败: %{public}s', JSON.stringify(err))
      return false
    }
  }

  /**
   * 获取测验历史
   */
  async getQuizHistory(limit: number = 10): Promise<QuizRecord[]> {
    if (!this.rdbStore) return []
    let resultSet: relationalStore.ResultSet | null = null
    const result: QuizRecord[] = []
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_QUIZ_RECORD)
        .equalTo('user_id', this.getCurrentUserId())
        .orderByDesc('quiz_time')
        .limitAs(limit)
      resultSet = await this.rdbStore.query(predicates)
      while (resultSet.goToNextRow()) {
        result.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          userId: resultSet.getLong(resultSet.getColumnIndex('user_id')),
          poemId: resultSet.getLong(resultSet.getColumnIndex('poem_id')),
          score: resultSet.getLong(resultSet.getColumnIndex('score')),
          quizTime: resultSet.getString(resultSet.getColumnIndex('quiz_time'))
        })
      }
    } catch (err) {
      console.error(TAG, '查询测验历史失败: %{public}s', JSON.stringify(err))
    } finally {
      resultSet?.close()
    }
    return result
  }

  /**
   * 获取测验总次数
   */
  async getQuizCount(): Promise<number> {
    if (!this.rdbStore) return 0
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const sql = `SELECT COUNT(*) AS cnt FROM ${TABLE_QUIZ_RECORD} WHERE user_id = ${this.getCurrentUserId()}`
      resultSet = await this.rdbStore.querySql(sql)
      if (resultSet.goToFirstRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('cnt'))
      }
      return 0
    } catch (err) {
      console.error(TAG, '查询测验总数失败: %{public}s', JSON.stringify(err))
      return 0
    } finally {
      resultSet?.close()
    }
  }

  // ==================== 聚合统计（图表用） ====================

  /**
   * 按朝代分组统计诗词数量
   */
  async getDynastyStats(): Promise<DynastyStat[]> {
    if (!this.rdbStore) return []
    let resultSet: relationalStore.ResultSet | null = null
    const result: DynastyStat[] = []
    try {
      const sql = `SELECT dynasty, COUNT(*) AS cnt FROM ${TABLE_POEM} GROUP BY dynasty ORDER BY cnt DESC`
      resultSet = await this.rdbStore.querySql(sql)
      while (resultSet.goToNextRow()) {
        result.push({
          dynasty: resultSet.getString(resultSet.getColumnIndex('dynasty')),
          count: resultSet.getLong(resultSet.getColumnIndex('cnt'))
        })
      }
    } catch (err) {
      console.error(TAG, '聚合统计失败: %{public}s', JSON.stringify(err))
    } finally {
      resultSet?.close()
    }
    return result
  }

  /**
   * 按分类分组统计诗词数量
   */
  async getCategoryStats(): Promise<CategoryStat[]> {
    if (!this.rdbStore) return []
    let resultSet: relationalStore.ResultSet | null = null
    const result: CategoryStat[] = []
    try {
      const sql = `SELECT category, COUNT(*) AS cnt FROM ${TABLE_POEM} GROUP BY category ORDER BY cnt DESC`
      resultSet = await this.rdbStore.querySql(sql)
      while (resultSet.goToNextRow()) {
        result.push({
          category: resultSet.getString(resultSet.getColumnIndex('category')),
          count: resultSet.getLong(resultSet.getColumnIndex('cnt'))
        })
      }
    } catch (err) {
      console.error(TAG, '分类统计失败: %{public}s', JSON.stringify(err))
    } finally {
      resultSet?.close()
    }
    return result
  }

  // ==================== 工具方法 ====================

  /**
   * ResultSet 行转 Poem 对象
   */
  private rowToPoem(rs: relationalStore.ResultSet): Poem {
    return {
      id: rs.getLong(rs.getColumnIndex('id')),
      title: rs.getString(rs.getColumnIndex('title')),
      author: rs.getString(rs.getColumnIndex('author')),
      dynasty: rs.getString(rs.getColumnIndex('dynasty')),
      content: rs.getString(rs.getColumnIndex('content')),
      category: rs.getString(rs.getColumnIndex('category')),
      imageId: rs.getString(rs.getColumnIndex('image_id'))
    }
  }

  /**
   * 获取当前时间字符串
   */
  // ==================== 打卡记录 ====================

  /**
   * 今日是否已打卡
   */
  async isCheckedInToday(): Promise<boolean> {
    if (!this.rdbStore) return false
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const today = new Date()
      const dateStr = today.getFullYear() + '-' + String(today.getMonth() + 1).padStart(2, '0') + '-' + String(today.getDate()).padStart(2, '0')
      const predicates = new relationalStore.RdbPredicates(TABLE_CHECKIN)
        .equalTo('user_id', this.getCurrentUserId())
        .equalTo('checkin_date', dateStr)
      resultSet = await this.rdbStore.query(predicates)
      return resultSet.rowCount > 0
    } catch (err) {
      console.error(TAG, '查询打卡状态失败')
      return false
    } finally {
      resultSet?.close()
    }
  }

  /**
   * 打卡
   */
  async doCheckin(poemTitle: string, content: string): Promise<boolean> {
    if (!this.rdbStore) return false
    try {
      const today = new Date()
      const dateStr = today.getFullYear() + '-' + String(today.getMonth() + 1).padStart(2, '0') + '-' + String(today.getDate()).padStart(2, '0')
      const valueBucket: relationalStore.ValuesBucket = {
        'user_id': this.getCurrentUserId(),
        'checkin_date': dateStr,
        'poem_title': poemTitle,
        'content': content,
        'create_time': this.getNowStr()
      }
      await this.rdbStore.insert(TABLE_CHECKIN, valueBucket)
      return true
    } catch (err) {
      console.error(TAG, '打卡失败: ' + JSON.stringify(err))
      return false
    }
  }

  /**
   * 获取连续打卡天数
   */
  async getConsecutiveCheckinDays(): Promise<number> {
    if (!this.rdbStore) return 0
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_CHECKIN)
        .equalTo('user_id', this.getCurrentUserId())
        .orderByDesc('checkin_date')
      resultSet = await this.rdbStore.query(predicates)
      if (resultSet.rowCount === 0) return 0

      let consecutive = 0
      const today = new Date()
      today.setHours(0, 0, 0, 0)

      while (resultSet.goToNextRow()) {
        const dateStr = resultSet.getString(resultSet.getColumnIndex('checkin_date'))
        const checkinDate = new Date(dateStr + 'T00:00:00')
        checkinDate.setHours(0, 0, 0, 0)

        const expectedDate = new Date(today)
        expectedDate.setDate(expectedDate.getDate() - consecutive)

        if (checkinDate.getTime() === expectedDate.getTime()) {
          consecutive++
        } else {
          break
        }
      }
      return consecutive
    } catch (err) {
      console.error(TAG, '查询连续打卡天数失败')
      return 0
    } finally {
      resultSet?.close()
    }
  }

  /**
   * 获取打卡历史
   */
  async getCheckinHistory(limit: number, offset: number): Promise<CheckInRecord[]> {
    if (!this.rdbStore) return []
    let resultSet: relationalStore.ResultSet | null = null
    const result: CheckInRecord[] = []
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_CHECKIN)
        .equalTo('user_id', this.getCurrentUserId())
        .orderByDesc('checkin_date')
        .limitAs(limit)
        .offsetAs(offset)
      resultSet = await this.rdbStore.query(predicates)
      while (resultSet.goToNextRow()) {
        result.push({
          date: resultSet.getString(resultSet.getColumnIndex('checkin_date')),
          poemTitle: resultSet.getString(resultSet.getColumnIndex('poem_title')),
          content: resultSet.getString(resultSet.getColumnIndex('content'))
        })
      }
    } catch (err) {
      console.error(TAG, '查询打卡历史失败')
    } finally {
      resultSet?.close()
    }
    return result
  }
  private getCurrentUserId(): number {
    try {
      const uid: number = StorageHelper.get<number>(KEY_USER_ID) ?? 1
      return uid
    } catch {
      return 1
    }
  }

  private getNowStr(): string {
    const now = new Date()
    const y = now.getFullYear()
    const m = String(now.getMonth() + 1).padStart(2, '0')
    const d = String(now.getDate()).padStart(2, '0')
    const h = String(now.getHours()).padStart(2, '0')
    const min = String(now.getMinutes()).padStart(2, '0')
    const s = String(now.getSeconds()).padStart(2, '0')
    return `${y}-${m}-${d} ${h}:${min}:${s}`
  }
}






