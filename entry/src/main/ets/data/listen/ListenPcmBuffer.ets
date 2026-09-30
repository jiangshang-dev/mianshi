/** 16kHz / 16bit / 单声道。最多留最近 3 分钟，避免一场长独白把内存撑满。 */
const MAX_PCM = 16000 * 2 * 180;

export class ListenPcmBuffer {
  private chunks: Uint8Array[] = [];
  private bytes: number = 0;

  append(chunk: Uint8Array): void {
    if (chunk.length === 0) {
      return;
    }
    const copy = new Uint8Array(chunk.length);
    copy.set(chunk);
    this.chunks.push(copy);
    this.bytes += copy.length;
    while (this.bytes > MAX_PCM && this.chunks.length > 1) {
      const dropped = this.chunks.shift();
      if (dropped !== undefined) {
        this.bytes -= dropped.length;
      }
    }
  }

  take(): Uint8Array {
    const out = new Uint8Array(this.bytes);
    let offset = 0;
    for (let i = 0; i < this.chunks.length; i++) {
      out.set(this.chunks[i], offset);
      offset += this.chunks[i].length;
    }
    this.clear();
    return out;
  }

  clear(): void {
    this.chunks = [];
    this.bytes = 0;
  }
}
