import { router } from '@kit.ArkUI'
import { DatabaseHelper } from '../model/DatabaseHelper'
import { Poem, DailyPoem, DailyPoemId } from '../common/Types'
import { PoemCategory as PoemCategoryEnum } from '../common/Enums'
import { PAGE_SIZE, KEY_DB_READY } from '../common/Constants'
import { PoemListItem } from '../components/PoemListItem'
import { ApiService } from '../services/ApiService'

@Component
export struct PoemListPage {
  @State poems: Poem[] = []
  @State isLoading: boolean = false
  @State hasMore: boolean = true
  @State currentPage: number = 0
  @State selectedCategory: string = ''
  @State searchKeyword: string = ''
  @State showCategoryMenu: boolean = false
  @State dailyPoem: DailyPoemId | null = null

  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()
  private apiService: ApiService = ApiService.getInstance()
  private categories: string[] = ['', PoemCategoryEnum.TANG_SHI, PoemCategoryEnum.SONG_CI, PoemCategoryEnum.YUAN_QU, PoemCategoryEnum.OTHER]
  private categoryNames: string[] = ['全部', '唐诗', '宋词', '元曲', '其他']

  aboutToAppear(): void {
    this.loadPoems(true)
    this.loadDailyPoem()
  }

  /**
   * 加载每日推荐（静默失败不影响主流程）
   */
  async loadDailyPoem(): Promise<void> {
    try {
      const res = await this.apiService.getDailyPoem()
      if (res.code === 0 && res.data) {
        this.dailyPoem = res.data
      }
    } catch (err) {
      // 网络不可用时使用本地默认推荐
      this.dailyPoem = {
        title: '静夜思',
        author: '李白',
        content: '床前明月光，疑是地上霜。举头望明月，低头思故乡。',
        reason: '此诗语言清新朴素，表达了思乡之情，是唐诗中的经典之作'
      } as DailyPoemId
    }
  }

  async loadPoems(reset: boolean): Promise<void> {
    if (this.isLoading) return
    if (!reset && !this.hasMore) return

    this.isLoading = true

    if (reset) {
      this.currentPage = 0
      this.hasMore = true
    }

    try {
      const offset = this.currentPage * PAGE_SIZE
      const result = await this.dbHelper.queryPoems(this.selectedCategory, this.searchKeyword, PAGE_SIZE, offset)

      if (reset) {
        this.poems = result
      } else {
        this.poems = this.poems.concat(result)
      }

      this.hasMore = result.length >= PAGE_SIZE
      if (result.length > 0) {
        this.currentPage++
      }
    } catch (err) {
      console.error('PoemListPage', '加载诗词列表失败')
    } finally {
      this.isLoading = false
    }
  }

  onCategorySelected(category: string): void {
    this.selectedCategory = category
    this.showCategoryMenu = false
    this.loadPoems(true)
  }

  onSearch(): void {
    this.loadPoems(true)
  }

  onPoemClick(poem: Poem): void {
    router.pushUrl({
      url: 'pages/PoemDetailPage',
      params: { poemId: poem.id }
    })
  }

  getCategoryName(): string {
    const index = this.categories.indexOf(this.selectedCategory)
    return index >= 0 ? this.categoryNames[index] : '全部'
  }

  build() {
    Column() {
      // 顶部搜索栏
      this.searchBar()

      // 分类筛选栏
      this.categoryBar()

      // 每日推荐
      if (this.dailyPoem) {
        this.dailyRecommendCard()
      }

      // 列表
      if (this.poems.length === 0 && !this.isLoading) {
        Column() {
          Text('暂无诗词数据')
            .fontSize(15)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 0 }) {
          LazyForEach(new PoemDataSource(this.poems), (poem: Poem, index: number) => {
            ListItem() {
              PoemListItem({
                poem: poem,
                onItemClick: (p: Poem) => { this.onPoemClick(p) }
              })
            }
          }, (poem: Poem) => poem.id.toString())

          // 加载更多指示器
          ListItem() {
            Row() {
              if (this.isLoading) {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color('#4A90D9')
                Blank().width(8)
                Text('加载中...')
                  .fontSize(13)
                  .fontColor('#999999')
              } else if (this.hasMore) {
                Text('上滑加载更多')
                  .fontSize(13)
                  .fontColor('#CCCCCC')
              } else {
                Text('— 已加载全部 —')
                  .fontSize(13)
                  .fontColor('#CCCCCC')
              }
            }
            .width('100%')
            .height(48)
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .onReachEnd(() => {
          this.loadPoems(false)
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  searchBar() {
    Row() {
      TextInput({ placeholder: '搜索诗词...', text: this.searchKeyword })
        .fontSize(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .height(36)
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .onChange((value: string) => {
          this.searchKeyword = value
        })
        .onSubmit(() => {
          this.onSearch()
        })

      if (this.searchKeyword) {
        Text('搜索')
          .fontSize(14)
          .fontColor('#4A90D9')
          .margin({ left: 10 })
          .onClick(() => {
            this.onSearch()
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  categoryBar() {
    Row() {
      Text(this.getCategoryName())
        .fontSize(14)
        .fontColor('#4A90D9')

      Text(' ▾')
        .fontSize(12)
        .fontColor('#4A90D9')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.showCategoryMenu = !this.showCategoryMenu
    })

    // 分类下拉
    if (this.showCategoryMenu) {
      Column() {
        ForEach(this.categoryNames, (categoryName: string, index: number) => {
          Row() {
            Text(categoryName)
              .fontSize(14)
              .fontColor(this.selectedCategory === this.categories[index] ? '#4A90D9' : '#333333')
              .fontWeight(this.selectedCategory === this.categories[index] ? FontWeight.Medium : FontWeight.Normal)
          }
          .width('100%')
          .height(40)
          .padding({ left: 16 })
          .backgroundColor(this.selectedCategory === this.categories[index] ? '#EDF4FF' : '#FFFFFF')
          .onClick(() => {
            this.onCategorySelected(this.categories[index])
          })

          if (index < this.categoryNames.length - 1) {
            Divider().strokeWidth(0.5).color('#EEEEEE')
          }
        })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
    }
  }

  @Builder
  dailyRecommendCard() {
    Row() {
      Column() {
        Text('📜').fontSize(18)
        Blank().width(10)
      }

      Column() {
        Row() {
          Text('今日推荐 · ')
            .fontSize(11)
            .fontColor('#F5A623')
            .fontWeight(FontWeight.Bold)
          Text(this.dailyPoem!.title)
            .fontSize(14)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
          Text(' — ')
            .fontSize(13)
            .fontColor('#999999')
          Text(this.dailyPoem!.author)
            .fontSize(13)
            .fontColor('#4A90D9')
        }

        Blank().height(6)

        Text(this.dailyPoem!.reason)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: 10 })

      Text('>')
        .fontSize(16)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFF9F0')
    .margin({ left: 12, right: 12, top: 10, bottom: 4 })
    .borderRadius(10)
    .onClick(() => {
      // 跳转到每日推荐详情（预留）
    })
  }
}

// ==================== LazyForEach 数据源 ====================

class PoemDataSource implements IDataSource {
  private poems: Poem[]
  private listeners: DataChangeListener[] = []

  constructor(poems: Poem[]) {
    this.poems = poems
  }

  totalCount(): number {
    return this.poems.length
  }

  getData(index: number): Poem {
    return this.poems[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }
}

