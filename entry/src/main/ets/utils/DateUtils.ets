/**
 * 日期工具类
 * 提供常用的日期格式化、计算等辅助方法
 */
export class DateUtils {
  /**
   * 格式化日期为 yyyy-MM-dd
   */
  static formatDate(date: Date): string {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, '0')
    const d = String(date.getDate()).padStart(2, '0')
    return `${y}-${m}-${d}`
  }

  /**
   * 格式化为完整的 yyyy-MM-dd HH:mm:ss
   */
  static formatDateTime(date: Date): string {
    const datePart = this.formatDate(date)
    const h = String(date.getHours()).padStart(2, '0')
    const min = String(date.getMinutes()).padStart(2, '0')
    const s = String(date.getSeconds()).padStart(2, '0')
    return `${datePart} ${h}:${min}:${s}`
  }

  /**
   * 获取相对时间描述（如"刚刚"、"3分钟前"、"2小时前"、"3天前"）
   */
  static getRelativeTime(dateStr: string): string {
    const now = new Date()
    const date = new Date(dateStr)
    const diff = now.getTime() - date.getTime()

    const seconds = Math.floor(diff / 1000)
    if (seconds < 60) return '刚刚'

    const minutes = Math.floor(seconds / 60)
    if (minutes < 60) return `${minutes}分钟前`

    const hours = Math.floor(minutes / 60)
    if (hours < 24) return `${hours}小时前`

    const days = Math.floor(hours / 24)
    if (days < 30) return `${days}天前`

    const months = Math.floor(days / 30)
    if (months < 12) return `${months}个月前`

    const years = Math.floor(months / 12)
    return `${years}年前`
  }

  /**
   * 获取本周的日期范围
   * @returns [周一日期, 周日日期]
   */
  static getCurrentWeekRange(): [string, string] {
    const now = new Date()
    const dayOfWeek = now.getDay() || 7 // 周日为7
    const monday = new Date(now)
    monday.setDate(now.getDate() - dayOfWeek + 1)
    const sunday = new Date(monday)
    sunday.setDate(monday.getDate() + 6)
    return [this.formatDate(monday), this.formatDate(sunday)]
  }

  /**
   * 计算两个日期之间的天数
   */
  static daysBetween(d1: string, d2: string): number {
    const date1 = new Date(d1)
    const date2 = new Date(d2)
    const diff = Math.abs(date2.getTime() - date1.getTime())
    return Math.floor(diff / (1000 * 60 * 60 * 24))
  }
}