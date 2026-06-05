# nota-zig 要件定義概要

## プロジェクト概要

nota-zig は Zig 向けの高性能 Lexer ジェネレータライブラリ。Rust の [logos](https://github.com/maciejhirsz/logos) に相当するポジションを Zig エコシステムで担う。comptime で正規表現を DFA にコンパイルし、ランタイムでは最小コストのテーブルドリブン実行のみを行うことで、手書き Lexer 同等以上の性能を実現する。

## スコープ

### 対象範囲

- comptime 関数 API による Lexer 型生成
- 正規表現エンジン（comptime DFA 生成）
- 文字列リテラル・正規表現・コールバックによるトークン定義
- バイトレベル（ASCII）処理
- ベンチマークスイート
- GitHub Actions CI（Zig 0.16.x）
- Zig package (build.zig.zon) による配布

### 対象外

- Unicode カテゴリ対応（`\p{L}` 等）
- ストリーミング入力（`std.io.Reader`）
- エラーリカバリ（パーサー統合）
- シンタックスハイライタ用途の最適化
- パーサージェネレータ機能

## 要件一覧

| ID | タイトル | 優先度 | ステータス |
|----|---------|--------|-----------|
| REQ-CORE-001 | comptime 関数 API による Lexer 型生成 | Must | Draft |
| REQ-CORE-002 | 文字列リテラルによるトークン定義 | Must | Draft |
| REQ-CORE-003 | コールバックによるカスタムマッチ | Must | Draft |
| REQ-CORE-004 | 定義順による優先度解決 | Must | Draft |
| REQ-CORE-005 | `[]const u8` 入力 | Must | Draft |
| REQ-CORE-006 | Token 出力形式（slice / offset 両対応） | Must | Draft |
| REQ-CORE-007 | エラートークン方式 | Must | Draft |
| REQ-CORE-008 | Iterator インターフェース | Must | Draft |
| REQ-REGEX-001 | 正規表現パーサー（comptime） | Must | Draft |
| REQ-REGEX-002 | NFA 構築（comptime） | Must | Draft |
| REQ-REGEX-003 | DFA 変換（comptime） | Must | Draft |
| REQ-REGEX-004 | 文字クラスサポート | Must | Draft |
| REQ-REGEX-005 | 量指定子サポート | Must | Draft |
| REQ-REGEX-006 | 選択・グループサポート | Must | Draft |
| REQ-REGEX-007 | 先読み・否定先読みサポート | Should | Draft |
| REQ-REGEX-008 | 非貪欲量指定子サポート | Should | Draft |
| REQ-PERF-001 | 手書き Lexer 同等以上の性能 | Must | Draft |
| REQ-PERF-002 | ベンチマークスイート | Must | Draft |
| REQ-INFRA-001 | Zig 0.16.x サポート | Must | Draft |
| REQ-INFRA-002 | Zig package 配布 | Must | Draft |
| REQ-INFRA-003 | mise タスク構成 | Must | Draft |
| REQ-INFRA-004 | GitHub Actions CI | Must | Draft |
| REQ-INFRA-005 | ファズテスト | Should | Draft |

## 用語集

| 用語 | 定義 |
|------|------|
| comptime | Zig のコンパイル時実行機能。関数やロジックをコンパイル時に評価できる |
| DFA | Deterministic Finite Automaton（決定性有限オートマトン）。状態遷移が一意に決まる有限状態機械 |
| NFA | Nondeterministic Finite Automaton（非決定性有限オートマトン）。ε遷移や複数遷移先を持つ有限状態機械 |
| Lexer | 字句解析器。入力文字列をトークン列に分割する |
| Token | Lexer の出力単位。トークン種別と対応する入力文字列の組 |
| 先読み (Lookahead) | 現在位置より先の文字列を消費せずに条件判定する正規表現機能 |
| logos | Rust の高性能 Lexer ジェネレータクレート。derive マクロで DFA を生成 |
| mise | タスクランナー兼バージョン管理ツール |
