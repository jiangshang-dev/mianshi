import { router } from '@kit.ArkUI';

interface LegalNav {
  kind?: string;
}

const AGREEMENT: string[] = [
  '欢迎使用码上 Offer（以下简称“本应用”）。在使用华为账号登录或继续使用本应用前，请认真阅读本协议。',
  '1. 服务内容',
  '本应用向你提供面试题库、学习记录、简历辅助与 AI 模拟面试等功能。我们可能持续优化题目、分类与面试体验。',
  '2. 账号',
  '你可通过华为账号登录。登录后，刷题进度、简历与学习数据将与该账号关联。请妥善保管你的华为账号，勿将账号借给他人使用。',
  '3. 使用规范',
  '你应合法使用本应用，不得利用本应用从事侵权、作弊、干扰服务或其它违法活动。题库与 AI 生成内容仅供学习参考，不构成任何录用承诺。',
  '4. 内容与知识产权',
  '本应用中的题目、解析、界面与商标等权益归权利人所有。未经许可，不得复制、传播或用于商业用途。',
  '5. 中断与变更',
  '因维护、升级或不可抗力，服务可能中断或调整。我们将在合理范围内进行说明。',
  '6. 协议更新',
  '我们可能更新本协议。更新后继续使用，即视为你接受修订后的内容。'
];

const PRIVACY: string[] = [
  '码上 Offer 重视你的个人信息保护。请结合《用户协议》阅读本政策。',
  '1. 我们收集的信息',
  '登录时，我们通过华为账号获取用于识别你的 OpenID / UnionID，以及你授权的昵称、头像。你主动上传的简历文本、刷题与面试记录也会保存在你的账号下。',
  '2. 使用目的',
  '上述信息用于账号登录、同步学习进度、结合简历生成面试题，以及改进学习体验。我们不会将简历和刷题记录用于与面试学习无关的用途。',
  '3. 存储与共享',
  '数据存储于本应用服务端。除法律法规要求或获得你的同意外，我们不会向无关第三方出售或共享你的个人信息。',
  '4. 你的权利',
  '你可在设置中退出登录。如需更正或删除账号数据，可通过应用内反馈或开发者联系方式提出请求。',
  '5. 政策更新',
  '本政策更新后，我们会在应用内提示。你继续使用即表示知晓相关变更。'
];

@Entry
@Component
struct LegalPage {
  @State private title: string = '用户协议';
  @State private paragraphs: string[] = AGREEMENT;

  aboutToAppear(): void {
    const nav = router.getParams() as LegalNav;
    if (nav !== undefined && nav.kind === 'privacy') {
      this.title = '隐私政策';
      this.paragraphs = PRIVACY;
    } else {
      this.title = '用户协议';
      this.paragraphs = AGREEMENT;
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .padding({ right: 8 })
          .onClick(() => router.back())
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.paragraphs, (text: string, idx: number) => {
            Text(text)
              .fontSize(15)
              .fontColor('#374151')
              .lineHeight(24)
              .width('100%')
          }, (text: string, idx: number) => `${idx}`)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F3F4F6')
  }
}
