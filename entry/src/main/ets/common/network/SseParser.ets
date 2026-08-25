import { AiStreamSnapshot } from '../models/Types';

export class SseParser {
  private leftover: string = '';
  private markdown: string = '';
  private thinking: string = '';
  private phase: string = 'thinking';
  private thinkingDone: boolean = false;

  feed(piece: string, onUpdate: (snap: AiStreamSnapshot) => void): void {
    this.leftover += piece.split('\r\n').join('\n').split('\r').join('\n');
    const parts = this.leftover.split('\n');
    this.leftover = parts.pop() ?? '';
    for (let i = 0; i < parts.length; i++) {
      this.consumeLine(parts[i].trim(), onUpdate);
    }
  }

  finish(onUpdate: (snap: AiStreamSnapshot) => void): string {
    if (this.leftover.length > 0) {
      this.consumeLine(this.leftover.trim(), onUpdate);
      this.leftover = '';
    }
    if (this.markdown.length === 0 && this.thinking.length > 0 && !this.thinkingDone) {
      this.thinkingDone = true;
      this.phase = 'answer';
      onUpdate(this.snapshot());
    }
    return this.markdown;
  }

  current(): string {
    return this.markdown;
  }

  private snapshot(): AiStreamSnapshot {
    return {
      thinking: this.thinking,
      markdown: this.markdown,
      phase: this.phase,
      thinkingDone: this.thinkingDone
    };
  }

  private consumeLine(line: string, onUpdate: (snap: AiStreamSnapshot) => void): void {
    if (line.length === 0 || line.charAt(0) === ':') {
      return;
    }
    let json = line;
    if (line.indexOf('data:') === 0) {
      json = line.substring(5).trim();
    }
    if (json.length === 0 || json === '[DONE]') {
      return;
    }
    if (json.charAt(0) !== '{') {
      return;
    }
    try {
      const chunk = JSON.parse(json) as Record<string, string>;
      const type = chunk.type ?? '';
      if (type === 'think_start') {
        this.phase = 'thinking';
        this.thinkingDone = false;
        onUpdate(this.snapshot());
      } else if (type === 'think_delta' || type === 'start') {
        this.phase = 'thinking';
        this.thinkingDone = false;
        if (chunk.thinking && chunk.thinking !== '正在思考…') {
          this.thinking = chunk.thinking;
        } else if (chunk.delta && chunk.delta.length > 0 && chunk.delta !== '正在思考…') {
          this.thinking += chunk.delta;
        }
        onUpdate(this.snapshot());
      } else if (type === 'think_end') {
        if (chunk.thinking && chunk.thinking.length > 0) {
          this.thinking = chunk.thinking;
        }
        this.thinkingDone = true;
        this.phase = 'answer';
        onUpdate(this.snapshot());
      } else if (type === 'delta') {
        if (!this.thinkingDone && this.thinking.length > 0) {
          this.thinkingDone = true;
        }
        this.phase = 'answer';
        if (chunk.markdown && chunk.markdown.length > 0) {
          this.markdown = chunk.markdown;
        } else if (chunk.delta && chunk.delta.length > 0) {
          this.markdown += chunk.delta;
        }
        onUpdate(this.snapshot());
      } else if (type === 'done') {
        if (this.thinking.length > 0) {
          this.thinkingDone = true;
        }
        this.phase = 'done';
        if (chunk.markdown && chunk.markdown.length > 0) {
          this.markdown = chunk.markdown;
        }
        onUpdate(this.snapshot());
      } else if (type === 'error') {
        const errText = chunk.delta || chunk.markdown || 'AI 生成失败';
        this.markdown = this.markdown.length > 0 ? this.markdown : errText;
        this.phase = 'error';
        onUpdate(this.snapshot());
      }
    } catch (_e) {
    }
  }
}
