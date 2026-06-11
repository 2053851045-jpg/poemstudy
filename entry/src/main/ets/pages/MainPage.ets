import { TabIndex } from '../common/Enums'
import { KEY_CURRENT_TAB } from '../common/Constants'
import { PoemListPage } from './PoemListPage'
import { QuizPage } from './QuizPage'
import { SocialPage } from './SocialPage'
import { ProfilePage } from './ProfilePage'

/**
 * 主页面 - 底部Tab导航框架
 *
 * 四个Tab页签：
 * 1. 诗词 - 诗词列表（搜索/筛选/每日推荐）
 * 2. 测验 - 诗词问答（随机抽题/计时/计分）
 * 3. 诗圈 - 社交动态（帖子列表/点赞/发布）
 * 4. 我的 - 个人中心（数据统计/图表/收藏/设置）
 *
 * 使用 @StorageLink 实现Tab切换状态的跨页面共享
 */
@Entry
@Component
struct MainPage {
  @StorageLink(KEY_CURRENT_TAB) currentTab: number = TabIndex.POEM_LIST
  private tabTitles: string[] = ['诗词', '测验', '诗圈', '我的']

  aboutToAppear(): void {
    // persistProp 已在 SplashPage 中完成
  }

  build() {
    Tabs({ index: this.currentTab }) {
      TabContent() {
        PoemListPageContent()
      }
      .tabBar(this.tabBarBuilder(TabIndex.POEM_LIST))

      TabContent() {
        QuizPageContent()
      }
      .tabBar(this.tabBarBuilder(TabIndex.QUIZ))

      TabContent() {
        SocialPageContent()
      }
      .tabBar(this.tabBarBuilder(TabIndex.SOCIAL))

      TabContent() {
        ProfilePageContent()
      }
      .tabBar(this.tabBarBuilder(TabIndex.PROFILE))
    }
    .barMode(BarMode.Fixed)
    .barWidth('100%')
    .barHeight(56)
    .animationDuration(200)
    .onChange((index: number) => {
      this.currentTab = index
    })
  }

  @Builder
  tabBarBuilder(index: number) {
    Column() {
      Text(this.getTabIcon(index))
        .fontSize(22)
        .fontColor(this.currentTab === index ? '#4A90D9' : '#999999')

      Text(this.tabTitles[index])
        .fontSize(11)
        .fontColor(this.currentTab === index ? '#4A90D9' : '#999999')
        .margin({ top: 2 })
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }

  getTabIcon(index: number): string {
    switch (index) {
      case TabIndex.POEM_LIST:
        return '📖'
      case TabIndex.QUIZ:
        return '✏️'
      case TabIndex.SOCIAL:
        return '💬'
      case TabIndex.PROFILE:
        return '👤'
      default:
        return '●'
    }
  }
}

// ==================== 四个 Tab 内容占位组件 ====================

@Component
struct PoemListPageContent {
  build() {
    PoemListPage()
  }
}

@Component
struct QuizPageContent {
  build() {
    QuizPage()
  }
}

@Component
struct SocialPageContent {
  build() {
    SocialPage()
  }
}

@Component
struct ProfilePageContent {
  build() {
    ProfilePage()
  }
}