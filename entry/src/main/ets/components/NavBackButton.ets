@Component
export struct NavBackButton {
  onBack: () => void = () => {
  };

  build() {
    Text('‹')
      .fontSize(28)
      .fontColor($r('app.color.text_primary'))
      .padding({ right: 8 })
      .onClick(() => this.onBack())
  }
}
