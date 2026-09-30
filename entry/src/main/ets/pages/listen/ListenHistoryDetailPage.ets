import { media } from '@kit.MediaKit';
import { promptAction, router } from '@kit.ArkUI';
import { I18n } from '../../common/i18n/I18n';
import { MdContentView } from '../../components/MdContentView';
import { ListenHistoryTurn, ListenRepository } from '../../data/repository/ListenRepository';

interface DetailRouteParams {
  sessionId?: string;
  title?: string;
}

@Entry
@Component
struct ListenHistoryDetailPage {
  @StorageLink('appLang') lang: string = I18n.HANS;
  @State private title: string = '辅助面试';
  @State private sessionId: string = '';
  @State private turns: ListenHistoryTurn[] = [];
  @State private loading: boolean = true;
  @State private playingId: string = '';
  private repo: ListenRepository = ListenRepository.getInstance();
  private player: media.AVPlayer | null = null;

  aboutToAppear(): void {
    const params = router.getParams() as DetailRouteParams;
    this.sessionId = params.sessionId !== undefined ? params.sessionId : '';
    const incoming = params.title !== undefined ? params.title : '';
    this.title = incoming.length > 0 ? incoming : I18n.t('listen_logs', this.lang);
    this.loadData();
  }

  aboutToDisappear(): void {
    this.stopPlay();
  }

  private async loadData(): Promise<void> {
    this.loading = true;
    try {
      this.turns = await this.repo.listTurns(this.sessionId);
    } catch (_e) {
      this.turns = [];
    } finally {
      this.loading = false;
    }
  }

  private async togglePlay(turn: ListenHistoryTurn): Promise<void> {
    if (turn.audioUrl.length === 0) {
      return;
    }
    if (this.playingId === turn.id) {
      await this.stopPlay();
      return;
    }
    await this.stopPlay();
    try {
      const player = await media.createAVPlayer();
      this.player = player;
      this.playingId = turn.id;
      player.on('stateChange', (state: media.AVPlayerState, _reason: media.StateChangeReason) => {
        if (this.player !== player) {
          return;
        }
        if (state === 'initialized') {
          player.prepare();
        } else if (state === 'prepared') {
          player.play();
        } else if (state === 'completed' || state === 'error') {
          setTimeout(() => {
            if (this.playingId === turn.id) {
              this.playingId = '';
            }
          }, 0);
        }
      });
      player.on('error', () => {
        setTimeout(() => {
          this.playingId = '';
          promptAction.showToast({ message: '原声暂时播不了' });
        }, 0);
      });
      player.url = turn.audioUrl;
    } catch (_e) {
      this.playingId = '';
      promptAction.showToast({ message: '原声暂时播不了' });
    }
  }

  private async stopPlay(): Promise<void> {
    const current = this.player;
    this.player = null;
    this.playingId = '';
    if (current === null) {
      return;
    }
    try {
      await current.release();
    } catch (_e) {
    }
  }

  private durationText(ms: number): string {
    if (ms <= 0) {
      return '';
    }
    const sec = Math.round(ms / 1000);
    return `${sec}秒`;
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
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.loading) {
        Column() {
          LoadingProgress().width(36).height(36)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.turns.length === 0) {
        Column() {
          Text(I18n.t('listen_hist_empty', this.lang))
            .fontSize(14)
            .fontColor($r('app.color.text_muted'))
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.turns, (turn: ListenHistoryTurn) => {
            ListItem() {
              this.turnCard(turn)
            }
          }, (turn: ListenHistoryTurn) => turn.id.length > 0 ? turn.id : `${turn.seq}`)
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

  @Builder
  private turnCard(turn: ListenHistoryTurn) {
    Column({ space: 10 }) {
      Row() {
        Text(`第 ${turn.seq} 题`)
          .fontSize(12)
          .fontColor('#5B4BDB')
          .layoutWeight(1)
        Text(turn.createTime)
          .fontSize(11)
          .fontColor($r('app.color.text_muted'))
      }
      .width('100%')

      Text('面试官')
        .fontSize(12)
        .fontColor('#6B7280')
        .width('100%')
      Text(turn.questionText.length > 0 ? turn.questionText : '（没有识别到原话）')
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      if (turn.audioUrl.length > 0) {
        Text(this.playingId === turn.id ? I18n.t('listen_stop', this.lang) :
          `${I18n.t('listen_play', this.lang)}${this.durationText(turn.audioMs).length > 0 ? ' ' + this.durationText(turn.audioMs) : ''}`)
          .fontSize(13)
          .fontColor('#2563EB')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(14)
          .backgroundColor('#EEF3FF')
          .onClick(() => {
            this.togglePlay(turn);
          })
      } else {
        Text(I18n.t('listen_no_audio', this.lang))
          .fontSize(12)
          .fontColor($r('app.color.text_muted'))
      }

      Text('可以这样说')
        .fontSize(12)
        .fontColor('#059669')
        .width('100%')
      MdContentView({ content: turn.answerText })
    }
    .width('100%')
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(12)
  }
}