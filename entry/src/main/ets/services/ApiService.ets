import { ApiResponse, LoginResponse, UserInfo, DailyPoemId, PostListData, SocialPost, PostDetailData } from '../common/Types'

const TAG = 'ApiService'

/**
 * API 服务单例（当前使用 Mock 数据）
 * 当后端服务不可用时，自动返回模拟数据保证功能可用
 */
export class ApiService {
  private static instance: ApiService

  static getInstance(): ApiService {
    if (!ApiService.instance) {
      ApiService.instance = new ApiService()
    }
    return ApiService.instance
  }

  async login(nickname: string): Promise<ApiResponse<LoginResponse>> {
    return {
      code: 0,
      message: 'success',
      data: {
        token: 'mock_token_' + Date.now(),
        userInfo: { nickname: nickname, avatar: '' }
      }
    }
  }

  async getUserInfo(): Promise<ApiResponse<UserInfo>> {
    return {
      code: 0,
      message: 'success',
      data: { nickname: '诗词爱好者', avatar: '' }
    }
  }

  async updateUserInfo(data: UserInfo): Promise<ApiResponse<null>> {
    return { code: 0, message: 'success', data: null }
  }

  async getDailyPoem(): Promise<ApiResponse<DailyPoemId>> {
    return {
      code: 0,
      message: 'success',
      data: {
        id: 1,
        title: '静夜思',
        author: '李白',
        content: '床前明月光，疑是地上霜。举头望明月，低头思故乡。',
        reason: '此诗语言清新朴素，表达了深切的思乡之情，是唐诗中的不朽名篇。'
      }
    }
  }

  async getSocialPosts(page: number, pageSize: number): Promise<ApiResponse<PostListData>> {
    return {
      code: 0,
      message: 'success',
      data: {
        list: [
          { id: 1, content: '今天读了李白的《将进酒》，"君不见黄河之水天上来"气势磅礴！', likes: 12, isLiked: false, createTime: '2026-06-11 10:30' },
          { id: 2, content: '苏轼的《水调歌头》真是千古绝唱，每次读都有新感悟。', likes: 8, isLiked: true, createTime: '2026-06-10 15:20' },
          { id: 3, content: '推荐王维的《山居秋暝》，诗中有画，画中有诗。', likes: 5, isLiked: false, createTime: '2026-06-10 09:15' }
        ],
        total: 3
      }
    }
  }

  async likePost(postId: number): Promise<ApiResponse<null>> {
    return { code: 0, message: 'success', data: null }
  }

  async unlikePost(postId: number): Promise<ApiResponse<null>> {
    return { code: 0, message: 'success', data: null }
  }

  async publishPost(content: string): Promise<ApiResponse<SocialPost>> {
    return {
      code: 0,
      message: 'success',
      data: { id: Date.now(), content: content, likes: 0, isLiked: false, createTime: '2026-06-11 12:00' }
    }
  }

  async getPostDetail(postId: number): Promise<ApiResponse<PostDetailData>> {
    return {
      code: 0,
      message: 'success',
      data: {
        post: { id: postId, content: '分享一首好诗给大家~', likes: 5, isLiked: false, createTime: '2026-06-11 10:00' },
        comments: [
          { id: 1, content: '写得太好了！', author: '诗友A', createTime: '2026-06-11 10:30' }
        ]
      }
    }
  }
}
