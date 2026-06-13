/**
 * 字符串工具类
 */
export class StringUtils {
  /**
   * 判断字符串是否为空
   */
  static isEmpty(str: string | null): boolean {
    return str === null || str === undefined || str.trim().length === 0
  }

  /**
   * 判断字符串是否非空
   */
  static isNotEmpty(str: string | null): boolean {
    return !this.isEmpty(str)
  }

  /**
   * 截断字符串，超出添加省略号
   */
  static truncate(str: string, maxLen: number): string {
    if (str.length <= maxLen) return str
    return str.substring(0, maxLen) + '...'
  }

  /**
   * 将句子按标点拆分
   */
  static splitSentences(str: string): string[] {
    return str.split(/[，。！？,\.!\?]/).filter(s => s.trim().length > 0)
  }

  /**
   * 获取随机颜色（十六进制）
   */
  static randomHexColor(): string {
    const hex = Math.floor(Math.random() * 0xFFFFFF).toString(16)
    return `#${hex.padStart(6, '0')}`
  }

  /**
   * 获取当前时间字符串（yyyy-MM-dd HH:mm:ss）
   */
  static getNow(): string {
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