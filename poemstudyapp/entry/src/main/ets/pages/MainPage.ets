import { TabIndex } from '../common/Enums'
import { StorageHelper } from '../utils/StorageHelper'
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
 */
@Entry
@Component
struct MainPage {
  @State currentTab: number = TabIndex.POEM_LIST
  private tabTitles: string[] = ['诗词', '测验', '打卡圈', '我的']

  aboutToAppear(): void {
    // 恢复上次 Tab
    const savedTab: number = StorageHelper.get<number>(KEY_CURRENT_TAB) ?? TabIndex.POEM_LIST
    this.currentTab = savedTab
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
      StorageHelper.set(KEY_CURRENT_TAB, index)
    })
  }

  @Builder
  tabBarBuilder(index: number) {
    Column() {
      Image(this.getTabIcon(index))
        .width(24)
        .height(24)
        .fillColor(this.currentTab === index ? '#4A90D9' : '#999999')

      Text(this.tabTitles[index])
        .fontSize(11)
        .fontColor(this.currentTab === index ? '#4A90D9' : '#999999')
        .margin({ top: 2 })
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }

  getTabIcon(index: number): Resource {
    switch (index) {
      case TabIndex.POEM_LIST:
        return $r('app.media.icon_poem')
      case TabIndex.QUIZ:
        return $r('app.media.icon_quiz')
      case TabIndex.SOCIAL:
        return $r('app.media.icon_social')
      case TabIndex.PROFILE:
        return $r('app.media.icon_profile')
      default:
        return $r('app.media.icon_poem')
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