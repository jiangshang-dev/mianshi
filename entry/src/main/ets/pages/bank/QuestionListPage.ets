import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { DataSourceType, QuestionItem, SubCategory } from '../../common/models/Types';
import { QuestionListItem } from '../../components/QuestionListItem';
import { QuestionRepository } from '../../data/repository/QuestionRepository';
import { I18n } from '../../common/i18n/I18n';

interface ListRouteParams {
  categoryId?: string;
  title?: string;
  source?: string;
}

@Entry
@Component
struct QuestionListPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private title: string = '题库';
  @State private categoryId: string = '';
  @State private source: DataSourceType = 'remote_api';
  @State private subCategories: SubCategory[] = [];
  @State private selectedSubId: string = '';
  @State private questions: QuestionItem[] = [];
  @State private loading: boolean = true;
  private repo: QuestionRepository = QuestionRepository.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as ListRouteParams;
    if (params) {
      this.categoryId = params.categoryId ?? '';
      this.title = params.title ?? '题库';
      this.source = (params.source as DataSourceType) ?? 'remote_api';
    }
    this.bootstrap();
  }

  private async bootstrap(): Promise<void> {
    this.loading = true;
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const cats = await this.repo.getCategories(ctx);
      const root = cats.find((c) => c.id === this.categoryId);
      if (root) {
        this.subCategories = root.children;
      } else {
        this.subCategories = [];
      }
      this.selectedSubId = '';
      await this.reloadList(ctx);
    } catch (_e) {
      this.questions = [];
    } finally {
      this.loading = false;
    }
  }

  private async reloadList(ctx?: common.UIAbilityContext): Promise<void> {
    const context = ctx ?? (getContext(this) as common.UIAbilityContext);
    this.loading = true;
    try {
      this.questions = await this.repo.listQuestions(
        context,
        this.categoryId,
        this.selectedSubId.length > 0 ? this.selectedSubId : undefined
      );
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_primary'))
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        // Text(this.source === 'local_md' ? '本地' : '远程')
        //   .fontSize(12)
        //   .fontColor(this.source === 'local_md' ? '#047857' : '#1D4ED8')
        //   .backgroundColor(this.source === 'local_md' ? '#D1FAE5' : '#DBEAFE')
        //   .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        //   .borderRadius(8)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.subCategories.length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            Text(I18n.t('all', this.lang))
              .fontSize(13)
              .fontColor(this.selectedSubId.length === 0 ? $r('app.color.text_on_color') : $r('app.color.chip_idle_text'))
              .backgroundColor(this.selectedSubId.length === 0 ? $r('app.color.accent') : $r('app.color.card_bg'))
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .borderRadius(16)
              .onClick(() => {
                this.selectedSubId = '';
                this.reloadList();
              })
            ForEach(this.subCategories, (sub: SubCategory) => {
              Text(sub.name)
                .fontSize(13)
                .fontColor(this.selectedSubId === sub.id ? $r('app.color.text_on_color') : $r('app.color.chip_idle_text'))
                .backgroundColor(this.selectedSubId === sub.id ? $r('app.color.accent') : $r('app.color.card_bg'))
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .borderRadius(16)
                .onClick(() => {
                  this.selectedSubId = sub.id;
                  this.reloadList();
                })
            }, (sub: SubCategory) => sub.id)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .padding({ bottom: 8 })
      }

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36)
        }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      } else if (this.questions.length === 0) {
        Column({ space: 8 }) {
          Text(I18n.t('empty', this.lang)).fontSize(16).fontColor($r('app.color.text_muted'))
          Text(I18n.t('empty_remote', this.lang))
            .fontSize(13).fontColor($r('app.color.text_muted'))
        }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.questions, (item: QuestionItem) => {
            ListItem() {
              QuestionListItem({
                item: item,
                onItemClick: (q: QuestionItem) => {
                  router.pushUrl({
                    url: 'pages/bank/QuestionDetailPage',
                    params: { 'id': q.id }
                  });
                }
              })
            }
          }, (item: QuestionItem) => item.id)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
