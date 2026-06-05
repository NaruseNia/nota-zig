# TASK-008: Lexer 型・Token 型・Iterator

- **関連要件**: REQ-CORE-001, REQ-CORE-006, REQ-CORE-008
- **規模**: M
- **依存タスク**: TASK-007

## 実装概要

ユーザーに公開する Lexer 型と Token 型を実装する。Iterator インターフェースとスキップ機能を含む。

## 対象ファイル

- `src/nota.zig`
- `src/lexer.zig`
- `src/token.zig`

## 実装ステップ

1. `token.zig` に Token 型を定義:
   - `SliceToken{ .tag, .slice }` と `OffsetToken{ .tag, .start, .end }` の 2 形式
   - `TokenFormat` に基づく comptime 型選択
2. `lexer.zig` に Lexer 構造体を実装:
   - `init(input)`, `next()`, `peek()`, `reset()`, `position()`, `rest()`
   - `skip` 設定に基づく自動スキップ
   - Token 形式に応じた出力生成
3. `nota.zig` に公開 API `Lexer` 関数を実装:
   - TokenEnum のフィールド走査
   - リテラル/正規表現/コールバックの分類
   - compiler を呼び出して DFA テーブル生成
   - テーブルを埋め込んだ Lexer 型を返す
4. 統合テスト: 簡単な言語（四則演算）の Lexer を定義してトークナイズ
