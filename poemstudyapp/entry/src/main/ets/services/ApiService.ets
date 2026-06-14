
import axios, { AxiosInstance, InternalAxiosRequestConfig } from '@ohos/axios'
import { ApiResponse, LoginResponse, LoginParams, UserInfo, UserAccount, DailyPoemId, PostListData, SocialPost, PostDetailData, SocialPostComment } from '../common/Types'
import { BASE_URL, REQUEST_TIMEOUT, KEY_TOKEN, KEY_USER_INFO, KEY_USER_ID } from '../common/Constants'
import { StorageHelper } from '../utils/StorageHelper'

const TAG = 'ApiService'

/**
 * 预定义教学用户（仿 week16_getpost 模式）
 * 考试固定密码统一为 "123456"
 */
const PREDEFINED_USERS: UserAccount[] = [
  { id: 1, username: 'student1', password: '123456', nickname: '诗韵书生', avatar: '', role: 'student' },
  { id: 2, username: 'student2', password: '123456', nickname: '墨香雅士', avatar: '', role: 'student' },
  { id: 3, username: 'student3', password: '123456', nickname: '竹影清风', avatar: '', role: 'student' },
  { id: 4, username: 'teacher', password: '123456', nickname: '诗词先生', avatar: '', role: 'teacher' },
  { id: 5, username: 'guest', password: '123456', nickname: '访客', avatar: '', role: 'guest' },
]

/**
 * API 服务单例
 * 使用 @ohos/axios 进行真实网络请求，后端不可用时自动降级为 Mock 数据
 *
 * 考点：
 * - axios.create 统一实例
 * - 请求头手动携带 token
 * - GET / POST 请求
 * - 登录鉴权流程
 */
export class ApiService {
  private static instance: ApiService
  private client: AxiosInstance

  static getInstance(): ApiService {
    if (!ApiService.instance) {
      ApiService.instance = new ApiService()
    }
    return ApiService.instance
  }

  private constructor() {
    this.client = axios.create({
      baseURL: BASE_URL,
      timeout: REQUEST_TIMEOUT,
      headers: { 'Content-Type': 'application/json' }
    })
    // 请求拦截器：自动携带 token
    this.client.interceptors.request.use((cfg: InternalAxiosRequestConfig<Object>) => {
      const token: string = StorageHelper.get<string>(KEY_TOKEN) ?? ''
      if (token && cfg.headers) {
        const headers: Record<string, string> = cfg.headers as Record<string, string>
        headers['Authorization'] = 'Bearer ' + token
      }
      return cfg
    })
  }

  /** 获取所有预定义用户（用于登录页选择） */
  static getPredefinedUsers(): UserAccount[] {
    return PREDEFINED_USERS
  }

  /**
   * 登录接口（axios POST）
   * POST /api/user/login
   * 仿 week16_getpost 模式：用户名+密码 → token
   *
   * 教学版密码统一为 "123456"
   */
  async login(params: LoginParams): Promise<ApiResponse<LoginResponse>> {
    try {
      const body: Record<string, string> = {
        'username': params.username,
        'password': params.password
      }
      const response: Record<string, Object> = await this.client.post('/user/login', body) as Record<string, Object>
      const res: ApiResponse<LoginResponse> = response['data'] as ApiResponse<LoginResponse>
      console.info(TAG, '登录请求成功')
      return res
    } catch (err) {
      // 网络不可用 → 使用本地 Mock 验证（教学降级）
      console.warn(TAG, '后端不可用，使用本地验证: ' + JSON.stringify(err))
      return this.localLogin(params)
    }
  }

  /**
   * 本地 Mock 登录验证（后端不可用时自动降级）
   * 仿 week16_getpost Python 后端的验证逻辑
   */
  private localLogin(params: LoginParams): ApiResponse<LoginResponse> {
    // 查找用户
    const user = PREDEFINED_USERS.find(u => u.username === params.username)

    if (!user) {
      return {
        code: 401,
        message: '用户不存在',
        data: { token: '', userInfo: { nickname: '', avatar: '' } }
      }
    }

    if (user.password !== params.password) {
      return {
        code: 401,
        message: '密码错误（教学版统一密码: 123456）',
        data: { token: '', userInfo: { nickname: '', avatar: '' } }
      }
    }

    // 生成 token（格式：jwt-mock-用户ID-时间戳）
    const token = 'jwt-mock-' + user.id + '-' + Date.now()
    const userInfo: UserInfo = {
      nickname: user.nickname,
      avatar: user.avatar,
      role: user.role
    }

    console.info(TAG, `本地验证通过: ${user.nickname}(${user.role})`)
    return {
      code: 0,
      message: '登录成功',
      data: { token: token, userInfo: userInfo }
    }
  }

  /**
   * 自定义游客登录（无需预定义账号）
   * 输入昵称直接进入
   */
  guestLogin(nickname: string): ApiResponse<LoginResponse> {
    const token = 'guest-mock-' + Date.now()
    const userInfo: UserInfo = {
      nickname: nickname || '访客',
      avatar: '',
      role: 'guest'
    }
    return {
      code: 0,
      message: '游客模式',
      data: { token: token, userInfo: userInfo }
    }
  }

  /**
   * 获取用户信息（axios GET）
   * GET /api/user/info
   */
  async getUserInfo(): Promise<ApiResponse<UserInfo>> {
    try {
      const response: Record<string, Object> = await this.client.get('/user/info') as Record<string, Object>
      const res: ApiResponse<UserInfo> = response['data'] as ApiResponse<UserInfo>
      return res
    } catch (err) {
      console.warn(TAG, '用户信息接口不可用，使用 Mock 数据')
      const userData: UserInfo = { nickname: '诗词爱好者', avatar: '', role: 'student' }
      const mockData: ApiResponse<UserInfo> = {
        code: 0,
        message: 'success',
        data: userData
      }
      return mockData
    }
  }

  async updateUserInfo(data: UserInfo): Promise<ApiResponse<null>> {
    try {
      const response: Record<string, Object> = await this.client.put('/user/info', data) as Record<string, Object>
      const res: ApiResponse<null> = response['data'] as ApiResponse<null>
      return res
    } catch (err) {
      const mockData: ApiResponse<null> = { code: 0, message: 'success', data: null }
      return mockData
    }
  }

  async getDailyPoem(): Promise<ApiResponse<DailyPoemId>> {
    try {
      const response: Record<string, Object> = await this.client.get('/daily-poem') as Record<string, Object>
      const res: ApiResponse<DailyPoemId> = response['data'] as ApiResponse<DailyPoemId>
      return res
    } catch (err) {
      const mockPoem: DailyPoemId = {
        id: 1,
        title: '静夜思',
        author: '李白',
        content: '床前明月光，疑是地上霜。举头望明月，低头思故乡。',
        reason: '此诗语言清新朴素，表达了深切的思乡之情，是唐诗中的不朽名篇。'
      }
      const mockData: ApiResponse<DailyPoemId> = {
        code: 0,
        message: 'success',
        data: mockPoem
      }
      return mockData
    }
  }

  /**
   * 获取打卡圈动态列表（axios GET）
   * GET /api/posts?page=&pageSize=
   */
  async getSocialPosts(page: number, pageSize: number): Promise<ApiResponse<PostListData>> {
    try {
      const params: Record<string, number> = { 'page': page, 'pageSize': pageSize }
      const response: Record<string, Object> = await this.client.get('/posts', { params: params }) as Record<string, Object>
      const res: ApiResponse<PostListData> = response['data'] as ApiResponse<PostListData>
      return res
    } catch (err) {
      console.warn(TAG, '动态列表接口不可用，使用 Mock 数据')
      const mockList: SocialPost[] = [
        new SocialPost(1, '今天读了李白的《将进酒》，气势磅礴！', 12, false, '2026-06-11 10:30'),
        new SocialPost(2, '苏轼的《水调歌头》真是千古绝唱，每次读都有新感悟。', 8, true, '2026-06-10 15:20'),
        new SocialPost(3, '推荐王维的《山居秋暝》，诗中有画，画中有诗。', 5, false, '2026-06-10 09:15')
      ]
      const postListData: PostListData = { list: mockList, total: mockList.length }
      const mockData: ApiResponse<PostListData> = {
        code: 0,
        message: 'success',
        data: postListData
      }
      return mockData
    }
  }

  /**
   * 点赞（axios POST）
   * POST /api/posts/:id/like
   */
  async likePost(postId: number): Promise<ApiResponse<null>> {
    try {
      const response: Record<string, Object> = await this.client.post('/posts/' + postId + '/like') as Record<string, Object>
      const res: ApiResponse<null> = response['data'] as ApiResponse<null>
      return res
    } catch (err) {
      const mockData: ApiResponse<null> = { code: 0, message: 'success', data: null }
      return mockData
    }
  }

  async unlikePost(postId: number): Promise<ApiResponse<null>> {
    try {
      const response: Record<string, Object> = await this.client.post('/posts/' + postId + '/unlike') as Record<string, Object>
      const res: ApiResponse<null> = response['data'] as ApiResponse<null>
      return res
    } catch (err) {
      const mockData: ApiResponse<null> = { code: 0, message: 'success', data: null }
      return mockData
    }
  }

  /**
   * 发布打卡动态（axios POST）
   * POST /api/posts
   */
  async publishPost(content: string): Promise<ApiResponse<SocialPost>> {
    try {
      const body: Record<string, string> = { 'content': content }
      const response: Record<string, Object> = await this.client.post('/posts', body) as Record<string, Object>
      const res: ApiResponse<SocialPost> = response['data'] as ApiResponse<SocialPost>
      return res
    } catch (err) {
      const mockPost: SocialPost = new SocialPost(Date.now(), content, 0, false, '2026-06-11 12:00')
      const mockData: ApiResponse<SocialPost> = {
        code: 0,
        message: 'success',
        data: mockPost
      }
      return mockData
    }
  }

  async getPostDetail(postId: number): Promise<ApiResponse<PostDetailData>> {
    try {
      const response: Record<string, Object> = await this.client.get('/posts/' + postId) as Record<string, Object>
      const res: ApiResponse<PostDetailData> = response['data'] as ApiResponse<PostDetailData>
      return res
    } catch (err) {
      const mockPost: SocialPost = new SocialPost(postId, '分享一首好诗给大家~', 5, false, '2026-06-11 10:00')
      const mockComment: SocialPostComment = { id: 1, content: '写得太好了！', author: '诗友A', createTime: '2026-06-11 10:30' }
      const mockComments: SocialPostComment[] = [mockComment]
      const mockDetail: PostDetailData = {
        post: mockPost,
        comments: mockComments
      }
      const mockData: ApiResponse<PostDetailData> = {
        code: 0,
        message: 'success',
        data: mockDetail
      }
      return mockData
    }
  }
}
