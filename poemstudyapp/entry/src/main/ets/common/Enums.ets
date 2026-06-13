/**
 * 诗词分类
 */
export enum PoemCategory {
  TANG_SHI = '唐诗',
  SONG_CI = '宋词',
  YUAN_QU = '元曲',
  OTHER = '其他'
}

/**
 * 朝代
 */
export enum Dynasty {
  TANG = '唐',
  SONG = '宋',
  YUAN = '元',
  MING = '明',
  QING = '清'
}

/**
 * 测验状态
 */
export enum QuizStatus {
  NOT_STARTED = 'NOT_STARTED',
  ANSWERING = 'ANSWERING',
  COMPLETED = 'COMPLETED'
}

/**
 * Tab 索引
 */
export enum TabIndex {
  POEM_LIST = 0,
  QUIZ = 1,
  SOCIAL = 2,
  PROFILE = 3
}

/**
 * 点赞动作
 */
export enum LikeAction {
  LIKE = 'like',
  UNLIKE = 'unlike'
}