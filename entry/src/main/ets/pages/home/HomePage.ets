import { router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { BookCategory } from '../../common/models/BookTypes';
import { mallStr } from '../../common/models/MallTypes';
import { BookRepository } from '../../data/repository/BookRepository';

@Component
export struct HomePage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private cats: BookCategory[] = [];
  @State private loading: boolean = true;
  private repo: BookRepository = BookRepository.getInstance();

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    try {
      this.cats = await this.repo.categories();
    } catch (_e) {
      this.cats = [];
    } finally {
      this.loading = false;
    }
  }

  private openSearch(): void {
    router.pushUrl({ url: 'pages/search/SearchPage' });
  }

  private openCat(cat: BookCategory): void {
    const id = mallStr(cat.id);
    if (id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/book/BookCategoryPage',
      params: {
        'categoryId': id,
        'title': mallStr(cat.name),
        'intro': mallStr(cat.intro),
        'icon': mallStr(cat.icon)
      }
    });
  }

  private catIntro(cat: BookCategory): string {
    const intro = mallStr(cat.intro);
    if (intro.length > 0) {
      return intro;
    }
    return I18n.t('book_cat_default', this.lang);
  }

  private catIcon(cat: BookCategory): string {
    const icon = mallStr(cat.icon);
    return icon.length > 0 ? icon : '📘';
  }

  private catBg(index: number): string {
    const colors: string[] = ['#FEE2E2', '#DBEAFE', '#EDE9FE', '#D1FAE5', '#FFEDD5', '#FCE7F3', '#E0F2FE', '#E9D5FF'];
    return colors[index % colors.length];
  }

  build() {
    Column() {
      Column({ space: 14 }) {
        Row() {
          Column({ space: 4 }) {
            Text(`${I18n.t('hello_candidate', this.lang)}👋`)
              .fontSize(14)
              .fontColor('#64748B')
            Text(I18n.t('app_name', this.lang))
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2563EB')
            Text(I18n.t('home_slogan_book', this.lang))
              .fontSize(12)
              .fontColor('#64748B')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Column({ space: 4 }) {
            Text(I18n.t('home_keep_short', this.lang))
              .fontSize(10)
              .fontColor('#93C5FD')
              .textAlign(TextAlign.End)
            Text('📚💻')
              .fontSize(28)
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')

        Row({ space: 8 }) {
          Text('🔍').fontSize(14)
          Text(I18n.t('home_search_ph', this.lang))
            .fontSize(14)
            .fontColor('#94A3B8')
            .layoutWeight(1)
        }
        .width('100%')
        .height(42)
        .padding({ left: 14, right: 14 })
        .backgroundColor('#FFFFFF')
        .borderRadius(21)
        .onClick(() => this.openSearch())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })
      .linearGradient({
        angle: 180,
        colors: [['#E8F1FF', 0], ['#F3F4F6', 1]]
      })

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36).color('#2563EB')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 14 }) {
            Row() {
              Column({ space: 4 }) {
                Text(I18n.t('book_all_cat', this.lang))
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#0F172A')
                Text(I18n.t('home_cat_sub', this.lang))
                  .fontSize(12)
                  .fontColor('#94A3B8')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text(I18n.t('home_cat_go', this.lang))
                .fontSize(11)
                .fontColor('#94A3B8')
            }
            .width('100%')

            if (this.cats.length === 0) {
              Text(I18n.t('book_empty', this.lang))
                .fontSize(13)
                .fontColor('#94A3B8')
                .padding({ top: 40 })
                .width('100%')
                .textAlign(TextAlign.Center)
            } else {
              Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
                ForEach(this.cats, (cat: BookCategory, index: number) => {
                  Row({ space: 10 }) {
                    Text(this.catIcon(cat))
                      .fontSize(22)
                      .width(42)
                      .height(42)
                      .textAlign(TextAlign.Center)
                      .borderRadius(12)
                      .backgroundColor(this.catBg(index))
                    Column({ space: 2 }) {
                      Text(mallStr(cat.name))
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#0F172A')
                      Text(this.catIntro(cat))
                        .fontSize(11)
                        .fontColor('#94A3B8')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    Text('›')
                      .fontSize(18)
                      .fontColor('#CBD5E1')
                  }
                  .width('48%')
                  .padding(12)
                  .margin({ bottom: 10 })
                  .backgroundColor('#FFFFFF')
                  .borderRadius(14)
                  .shadow({ radius: 8, color: '#0F000000', offsetY: 2 })
                  .onClick(() => this.openCat(cat))
                }, (cat: BookCategory) => mallStr(cat.id))
              }
              .width('100%')
            }

            Row() {
              Text('🎓')
                .fontSize(16)
                .margin({ right: 6 })
              Text(I18n.t('home_banner', this.lang))
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
            .margin({ top: 4, bottom: 20 })
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }
}
