# PoemStudy · 古诗词学习 App

> HarmonyOS 期末项目 · 基于 ArkTS + relationalStore + axios

## 项目简介

一款基于 HarmonyOS NEXT (API 12) 的古诗词学习应用。用户可以浏览诗词库、收藏喜欢的诗词、进行诗词测验、每日打卡签到、在打卡圈互动，并查看个人学习数据统计。

## 约束版本（开发前必读）

| 文档 | 版本 |
|------|------|
| [技术栈约束](docs/1-项目约束/技术栈约束.md) | v1.0 |
| [数据模型约束](docs/1-项目约束/数据模型约束.md) | v1.0 |
| [API 接口约定](docs/1-项目约束/API接口约定.md) | v1.0 |
| [代码规范](docs/1-项目约束/代码规范.md) | v1.0 |
| [里程碑](docs/2-开发计划/里程碑.md) | v1.0 |
| [任务拆分](docs/2-开发计划/任务拆分.md) | v1.0 |
| [角色定义](docs/3-AI协作/角色定义.md) | v1.0 |
| [常见陷阱](docs/3-AI协作/常见陷阱与纠正规则.md) | v1.0 |
| [提示词模板](docs/3-AI协作/提示词模板库.md) | v1.0 |
| [验收标准](docs/4-测试与核对/验收标准.md) | v1.0 |

## 技术栈

- **框架**: HarmonyOS ArkTS / Stage 模型
- **SDK**: API 12 (HarmonyOS NEXT)
- **数据库**: @ohos.data.relationalStore
- **网络**: @ohos/axios
- **状态管理**: AppStorage / PersistentStorage / @State / @Observed
- **开发工具**: DevEco Studio 5.0.0+

## 硬性指标

| 指标 | 要求 |
|------|------|
| 本地数据库表 | ≥ 4 张（poem / favorite / quiz_record / checkin） |
| 核心内容数据 | ≥ 300 条 |
| 图片资源 | ≥ 30 张 |
| axios 接口 | ≥ 2 个 |
| 页面数量 | 7-9 个 |
| 自定义组件 | 3-4 个 |
| 数据可视化图表 | ≥ 1 个 |

## 开发进度

- [x] M1: 数据层 + 种子数据
- [x] M2: 基础页面 + 导航框架
- [x] M3: 交互功能（测验）
- [ ] M4: 网络功能（打卡圈）+ 图表
- [x] M5: 集成测试 + 收尾

## 项目结构

```
entry/src/main/ets/
├── common/          # 常量、枚举、接口定义
├── model/           # 数据库实体和操作类
├── services/        # 网络请求封装
├── components/      # 自定义组件
├── pages/           # 页面文件
└── utils/           # 工具函数
```

## GitHub

https://github.com/2053851045-jpg/poemstudy.git