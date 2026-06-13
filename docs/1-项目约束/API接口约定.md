# API 接口约定（v1.1 已对齐代码实现）

🔒 约束版本 v1.0
最后更新：2026-06-12
维护人：[廖雨辰]

---

## 变更记录

| 版本 | 日期 | 变更内容 | 变更人 |
|------|------|----------|--------|
| v1.0 | 2026-06-11 | 初始创建（4个接口定义）→ v1.1 对齐真实路径、增加打卡接口 | [廖雨辰] |

---

## 一、基础配置

```
Base URL: http://localhost:3000/api   [开发环境] / 需替换为真实 Mock 服务器地址
超时时间：10000ms
请求头：
  - Content-Type: application/json
  - Authorization: Bearer <token>  （需要登录的接口必须携带）
```

⚠️ **强制要求**：所有请求统一使用 `axios.create()` 单例实例，并在拦截器中统一添加 Token 和错误处理。

---

## 二、接口详细定义

### 接口 1：登录

| 项 | 内容 |
|----|------|
| 方法 | POST |
| 路径 | `/api/login` |
| 是否需要登录 | 否 |
| 请求体 | `{ "nickname": "string" }` |
| 成功响应 | `{ "code": 0, "message": "success", "data": { "token": "string", "userInfo": { "nickname": "string", "avatar": "string" } } }` |
| 失败响应 | `{ "code": 400, "message": "请求参数错误" }` |

**Mock 行为**：任意昵称均返回成功，token 格式：`mock_token_` + 时间戳。

### 接口 2：获取打卡圈动态列表

| 项 | 内容 |
|----|------|
| 方法 | GET |
| 路径 | `/api/posts` |
| 是否需要登录 | 是 |
| 请求参数 | `?page=1&pageSize=20` |
| 成功响应 | `{ "code": 0, "data": { "list": [ { "id": 1, "content": "string", "likes": 0, "isLiked": false, "createTime": "2026-06-11T10:00:00Z" } ], "total": 0 } }` |

### 接口 3：点赞

| 项 | 内容 |
|----|------|
| 方法 | POST |
| 路径 | `/api/posts/:id/like` |
| 是否需要登录 | 是 |
| 路径参数 | `id` — 帖子 ID |
| 成功响应 | `{ "code": 0, "message": "success", "data": null }` |

**Mock 行为**：任意帖子 ID 均返回成功。

### 接口 4：取消点赞

| 项 | 内容 |
|----|------|
| 方法 | POST |
| 路径 | `/api/posts/:id/unlike` |
| 是否需要登录 | 是 |
| 成功响应 | `{ "code": 0, "message": "success", "data": null }` |

### 接口 5：发布打卡动态

| 项 | 内容 |
|----|------|
| 方法 | POST |
| 路径 | `/api/posts` |
| 是否需要登录 | 是 |
| 请求体 | `{ "content": "string" }` |
| 成功响应 | `{ "code": 0, "data": { "id": 2, "content": "...", "likes": 0, "isLiked": false, "createTime": "..." } }` |

### 接口 6：获取帖子详情

| 项 | 内容 |
|----|------|
| 方法 | GET |
| 路径 | `/api/posts/:id` |
| 是否需要登录 | 是 |
| 成功响应 | `{ "code": 0, "data": { "post": { ... }, "comments": [...] } }` |

---

### 降级策略

所有接口在**后端不可用时自动降级返回 Mock 数据**，保证 App 在离线环境下的核心功能可用性：

- 登录接口降级 → 生成本地 mock token
- 帖子列表降级 → 返回 7 条本地预置帖子
- 点赞/发布降级 → 本地直接更新状态
- 每日推荐降级 → 返回《静夜思》作为默认推荐

---

## 三、错误码约定

| code 值 | 含义 |
|---------|------|
| 0 | 成功 |
| 400 | 请求参数错误 |
| 401 | Token 无效或已过期 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## 四、拦截器要求

- **请求拦截器**：自动从 AppStorage 读取 token，添加到 `Authorization` 请求头
- **响应拦截器**：统一解包 `res.data`，401 错误自动清除本地 token 并跳转登录页
- 详细实现见 `services/ApiService.ets`

---

## 五、禁止行为

- ❌ 每个接口单独创建 axios 实例（必须复用单例）
- ❌ 硬编码 token 到请求代码中
- ❌ 忘记处理网络异常（必须 try-catch + Toast 提示用户）