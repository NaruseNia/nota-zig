# TASK-010: ベンチマークスイート

- **関連要件**: REQ-PERF-002
- **規模**: M
- **依存タスク**: TASK-008

## 実装概要

手書き Lexer との性能比較ベンチマークを作成する。JSON Lexer と C-like 言語 Lexer の 2 種類。

## 対象ファイル

- `bench/json_lexer.zig` — JSON Lexer (nota-zig)
- `bench/json_handwritten.zig` — JSON Lexer (手書き)
- `bench/clike_lexer.zig` — C-like Lexer (nota-zig)
- `bench/clike_handwritten.zig` — C-like Lexer (手書き)
- `bench/main.zig` — ベンチマークランナー
- `bench/data/` — テスト入力データ

## 実装ステップ

1. ベンチマークフレームワークを作成:
   - ウォームアップ（5回）
   - 測定（100回）
   - 統計出力（平均, min, max, p50, p99）
   - スループット（MB/s）計算
2. JSON Lexer を実装:
   - nota-zig 版: `{`, `}`, `[`, `]`, `:`, `,`, `true`, `false`, `null`, number, string
   - 手書き版: switch-case ベースの等価実装
3. C-like 言語 Lexer を実装:
   - nota-zig 版: キーワード(20個程度), 演算子, 数値, 識別子, 文字列, コメント
   - 手書き版: switch-case ベースの等価実装
4. テスト入力データ:
   - JSON: 実用的な JSON ファイル（10KB, 100KB, 1MB）
   - C-like: C コードサンプル（10KB, 100KB）
5. `build.zig` にベンチマークステップを追加
6. `mise run bench` で実行できることを確認
