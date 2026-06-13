/**
 * 防抖工具类
 * 用于防止连续点击重复调用接口
 */
export class Debouncer {
  private delay: number
  private timerId: number | null = null

  constructor(delayMs: number = 300) {
    this.delay = delayMs
  }

  /**
   * 执行防抖操作
   */
  run(fn: () => void): void {
    if (this.timerId !== null) {
      clearTimeout(this.timerId)
    }
    this.timerId = setTimeout(() => {
      fn()
      this.timerId = null
    }, this.delay)
  }

  /**
   * 取消当前等待中的操作
   */
  cancel(): void {
    if (this.timerId !== null) {
      clearTimeout(this.timerId)
      this.timerId = null
    }
  }
}