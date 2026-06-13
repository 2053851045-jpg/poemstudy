import { router } from '@kit.ArkUI'
import { DatabaseHelper } from '../model/DatabaseHelper'
import { Poem } from '../common/Types'
import { PoemListItem } from '../components/PoemListItem'
import { NavHeader } from '../components/NavHeader'
import { EmptyState } from '../components/EmptyState'

@Entry
@Component
struct FavoritesPage {
  @State favorites: Poem[] = []
  @State isLoading: boolean = true

  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()

  aboutToAppear(): void {
    this.loadFavorites()
  }

  async loadFavorites(): Promise<void> {
    this.isLoading = true
    try {
      this.favorites = await this.dbHelper.queryFavorites(100, 0)
    } catch (err) {
      console.error('FavoritesPage', '加载收藏列表失败')
    } finally {
      this.isLoading = false
    }
  }

  onPoemClick(poem: Poem): void {
    router.pushUrl({
      url: 'pages/PoemDetailPage',
      params: { poemId: poem.id }
    })
  }

  build() {
    Column() {
      // 导航栏
      NavHeader({
        title: '我的收藏',
        showBack: true,
        backCallback: () => { router.back() }
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(28).height(28).color('#4A90D9')
          Blank().height(10)
          Text('加载中...').fontSize(14).fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.favorites.length === 0) {
        EmptyState({
          icon: '❤️',
          title: '还没有收藏',
          subtitle: '去诗词库发现喜欢的诗词吧~',
          showRetry: false
        })
        .layoutWeight(1)
      } else {
        List({ space: 0 }) {
          ForEach(this.favorites, (poem: Poem) => {
            ListItem() {
              PoemListItem({
                poem: poem,
                onItemClick: (p: Poem) => { this.onPoemClick(p) }
              })
            }
          }, (poem: Poem) => poem.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}