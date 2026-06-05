# nota-zig

Zig 向け高性能 Lexer ジェネレータライブラリ。comptime DFA 生成により手書き Lexer 同等以上の性能を実現する。

## 開発環境

- 言語: Zig 0.16.x
- タスクランナー: mise
- ライセンス: MIT

## タスク

- `mise run build` — ビルド
- `mise run test` — テスト
- `mise run bench` — ベンチマーク
- `mise run fuzz` — ファズテスト
- `mise run lint` — 静的解析
- `mise run fmt` — フォーマット
- `mise run clean` — クリーン

## ドキュメント整合性

- 作業完了時、docs/ 配下の要件定義書・仕様書・実装計画書に影響する変更がないか確認し、必要なら更新するかユーザーに確認すること
