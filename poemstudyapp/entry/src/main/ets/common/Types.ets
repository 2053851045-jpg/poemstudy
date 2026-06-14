/**
 * 诗词实体
 */
export interface Poem {
  id: number
  title: string
  author: string
  dynasty: string
  content: string
  category: string
  imageId: string
}

/**
 * 收藏实体
 */
export interface Favorite {
  id: number
  userId: number
  poemId: number
  createTime: string
}

/**
 * 测验记录
 */
export interface QuizRecord {
  id: number
  userId: number
  poemId: number
  score: number
  quizTime: string
}

/**
 * 用户信息（登录后获取）
 */
export interface UserInfo {
  nickname: string
  avatar: string
  role?: string
}

/**
 * 用户账号（预定义用户表）
 */
export interface UserAccount {
  id: number
  username: string
  password: string
  nickname: string
  avatar: string
  role: string       // 'student' | 'teacher' | 'guest'
}

/**
 * 登录参数
 */
export interface LoginParams {
  username: string
  password: string
}

/**
 * 登录响应
 */
export interface LoginResponse {
  token: string
  userInfo: UserInfo
}

/**
 * 诗圈帖子（@Observed 深度响应）
 */
@Observed
export class SocialPost {
  id: number
  content: string
  likes: number
  isLiked: boolean
  createTime: string

  constructor(id: number, content: string, likes: number, isLiked: boolean, createTime: string) {
    this.id = id
    this.content = content
    this.likes = likes
    this.isLiked = isLiked
    this.createTime = createTime
  }
}

/**
 * 朝代统计（图表用）
 */
export interface DynastyStat {
  dynasty: string
  count: number
}

/**
 * API 统一响应结构
 */
export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

/**
 * 每日诗词推荐
 */
export interface DailyPoem {
  title: string
  author: string
  content: string
  reason: string
}

/**
 * 朝代统计（带颜色，图表用）
 */
export interface DynastyStatWithColor extends DynastyStat {
  color: string
}

/**
 * 分类统计
 */
export interface CategoryStat {
  category: string
  count: number
}

/**
 * 每日诗词（含 id）
 */
export interface DailyPoemId {
  id: number
  title: string
  author: string
  content: string
  reason: string
}

/**
 * 帖子详情数据
 */
export interface PostDetailData {
  post: SocialPost
  comments: SocialPostComment[]
}

/**
 * 帖子评论
 */
export interface SocialPostComment {
  id: number
  content: string
  author: string
  createTime: string
}

export interface PostListData {
  list: SocialPost[]
  total: number
}

/**
 * 打卡历史记录
 */
export interface CheckInRecord {
  date: string
  poemTitle: string
  content: string
}

/**
 * 注册用户（DB user 表映射）
 */
export interface RegisteredUser {
  id: number
  username: string
  password: string
  nickname: string
  avatar: string
  createTime: string
}

/**
 * 帖子评论（@Observed 深度响应）
 */
@Observed
export class PostComment {
  id: number
  postId: number
  userId: number
  nickname: string
  parentId: number     // 0=根评论 >0=回复某条评论
  content: string
  likes: number
  isLiked: boolean
  createTime: string

  constructor(id: number, postId: number, userId: number, nickname: string,
              parentId: number, content: string, likes: number, isLiked: boolean, createTime: string) {
    this.id = id
    this.postId = postId
    this.userId = userId
    this.nickname = nickname
    this.parentId = parentId
    this.content = content
    this.likes = likes
    this.isLiked = isLiked
    this.createTime = createTime
  }
}

/**
 * 社交 Feed 条目（帖子 + 评论列表，用于 SocialPage 渲染）
 */
@Observed
export class SocialFeedItem {
  id: number
  userId: number
  nickname: string
  content: string
  likes: number
  isLiked: boolean
  commentCount: number
  comments: PostComment[]
  createTime: string

  constructor(id: number, userId: number, nickname: string, content: string,
              likes: number, isLiked: boolean, commentCount: number, comments: PostComment[], createTime: string) {
    this.id = id
    this.userId = userId
    this.nickname = nickname
    this.content = content
    this.likes = likes
    this.isLiked = isLiked
    this.commentCount = commentCount
    this.comments = comments
    this.createTime = createTime
  }
}
