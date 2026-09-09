import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { BookItem } from '../../common/models/BookTypes';
import { mallNum, mallStr } from '../../common/models/MallTypes';
import { BookCover } from '../../components/BookCover';
import { NavBackButton } from '../../components/NavBackButton';
import { BookRepository } from '../../data/repository/BookRepository';

interface BookCatParams {
  categoryId?: string;
  title?: string;
  intro?: string;
  icon?: string;
}

interface BookRow {
  a: BookItem;
  b: BookItem;
  hasB: boolean;
  key: string;
}

@Entry
@Component
struct BookCategoryPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private loading: boolean = true;
  @State private catId: string = '';
  @State private title: string = '';
  @State private intro: string = '';
  @State private icon: string = '📘';
  @State private tag: string = '';
  @State private tags: string[] = [];
  @State private list: BookItem[] = [];
  private repo: BookRepository = BookRepository.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as BookCatParams;
    this.catId = params !== undefined && params.categoryId !== undefined ? params.categoryId : '';
    this.title = params !== undefined && params.title !== undefined ? params.title : '';
    this.intro = params !== undefined && params.intro !== undefined ? params.intro : '';
    this.icon = params !== undefined && params.icon !== undefined && params.icon.length > 0 ? params.icon : '📘';
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    try {
      const page = await this.repo.list('', this.catId, 1);
      this.list = page.records !== undefined ? page.records : [];
      this.tags = this.collectTags(this.list);
    } catch (_e) {
      this.list = [];
      this.tags = [];
    } finally {
      this.loading = false;
    }
  }

  private collectTags(items: BookItem[]): string[] {
    const out: string[] = [];
    for (let i = 0; i < items.length; i++) {
      const t = mallStr(items[i].tag);
      if (t.length > 0 && out.indexOf(t) < 0) {
        out.push(t);
      }
    }
    return out;
  }

  private filtered(): BookItem[] {
    if (this.tag.length === 0) {
      return this.list;
    }
    const out: BookItem[] = [];
    for (let i = 0; i < this.list.length; i++) {
      if (mallStr(this.list[i].tag) === this.tag) {
        out.push(this.list[i]);
      }
    }
    return out;
  }

  private rows(): BookRow[] {
    const items = this.filtered();
    const rows: BookRow[] = [];
    for (let i = 0; i < items.length; i += 2) {
      const row: BookRow = {
        a: items[i],
        b: i + 1 < items.length ? items[i + 1] : {},
        hasB: i + 1 < items.length,
        key: mallStr(items[i].id)
      };
      rows.push(row);
    }
    return rows;
  }

  private openReader(item: BookItem): void {
    const id = mallStr(item.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/book/BookReaderPage',
      params: { 'id': id }
    });
  }

  private authorText(item: BookItem): string {
    const name = mallStr(item.authorName);
    if (name.length === 0) {
      return '';
    }
    return I18n.tf('book_author_suf', name, this.lang);
  }

  build() {
    Column() {
      Row() {
        NavBackButton({ onBack: () => router.back() })
        Text(I18n.tf('book_cat_title', this.title.length > 0 ? this.title : '…', this.lang))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#0F172A')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Blank().width(36).height(36)
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 12 })
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36).color('#2563EB')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ListItem() {
            Row({ space: 12 }) {
              Text(this.icon)
                .fontSize(28)
                .width(56)
                .height(56)
                .textAlign(TextAlign.Center)
                .borderRadius(14)
                .backgroundColor('#FEE2E2')
              Column({ space: 4 }) {
                Text(this.title)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#0F172A')
                Text(this.intro.length > 0 ? this.intro : I18n.t('book_cat_default', this.lang))
                  .fontSize(12)
                  .fontColor('#64748B')
                  .maxLines(2)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
          }

          if (this.tags.length > 0) {
            ListItem() {
              Scroll() {
                Row({ space: 8 }) {
                  Text(I18n.t('book_filter_all', this.lang))
                    .fontSize(13)
                    .fontColor(this.tag.length === 0 ? '#FFFFFF' : '#475569')
                    .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                    .borderRadius(16)
                    .backgroundColor(this.tag.length === 0 ? '#2563EB' : '#F1F5F9')
                    .onClick(() => {
                      this.tag = '';
                    })
                  ForEach(this.tags, (t: string) => {
                    Text(t)
                      .fontSize(13)
                      .fontColor(this.tag === t ? '#FFFFFF' : '#475569')
                      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                      .borderRadius(16)
                      .backgroundColor(this.tag === t ? '#2563EB' : '#F1F5F9')
                      .onClick(() => {
                        this.tag = t;
                      })
                  }, (t: string) => t)
                }
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
              .width('100%')
            }
          }

          ListItem() {
            Row() {
              Text(I18n.tf('book_count', `${this.filtered().length}`, this.lang))
                .fontSize(13)
                .fontColor('#64748B')
              Blank()
              Text(I18n.t('book_sort', this.lang))
                .fontSize(13)
                .fontColor('#64748B')
                .onClick(() => {
                  promptAction.showToast({ message: I18n.t('book_sort', this.lang) });
                })
            }
            .width('100%')
          }

          if (this.filtered().length === 0) {
            ListItem() {
              Text(I18n.t('book_empty', this.lang))
                .fontSize(13)
                .fontColor('#94A3B8')
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 40, bottom: 40 })
            }
          } else {
            ForEach(this.rows(), (row: BookRow) => {
              ListItem() {
                Row({ space: 10 }) {
                  this.bookCard(row.a)
                  if (row.hasB) {
                    this.bookCard(row.b)
                  } else {
                    Column().layoutWeight(1)
                  }
                }
                .width('100%')
              }
            }, (row: BookRow) => row.key)
          }

          ListItem() {
            Row() {
              Text('🎓')
                .fontSize(14)
                .margin({ right: 6 })
              Text(I18n.t('home_banner_short', this.lang))
                .fontSize(12)
                .fontColor('#1E40AF')
                .layoutWeight(1)
              Text(I18n.t('app_name', this.lang))
                .fontSize(10)
                .fontColor('#93C5FD')
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#DBEAFE')
            .borderRadius(12)
            .margin({ bottom: 16 })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }

  @Builder
  bookCard(item: BookItem) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        BookCover({ item: item, coverWidth: 56, coverHeight: 76 })
        Column({ space: 4 }) {
          Text(mallStr(item.title))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#0F172A')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.authorText(item))
            .fontSize(11)
            .fontColor('#94A3B8')
            .maxLines(1)
          Row({ space: 4 }) {
            if (mallStr(item.tag).length > 0) {
              Text(mallStr(item.tag))
                .fontSize(10)
                .fontColor('#2563EB')
                .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                .backgroundColor('#DBEAFE')
                .borderRadius(8)
            }
            if (mallStr(item.categoryName).length > 0) {
              Text(mallStr(item.categoryName))
                .fontSize(10)
                .fontColor('#B45309')
                .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                .backgroundColor('#FEF3C7')
                .borderRadius(8)
            }
          }
          Text(I18n.t('book_view', this.lang))
            .fontSize(11)
            .fontColor('#2563EB')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor('#DBEAFE')
            .borderRadius(10)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .layoutWeight(1)
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 6, color: '#0F000000', offsetY: 2 })
    .onClick(() => this.openReader(item))
  }
}
