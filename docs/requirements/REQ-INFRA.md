# REQ-INFRA: インフラ・ツーリング

## REQ-INFRA-001: Zig 0.16.x サポート

- **優先度**: Must
- **ステータス**: Draft
- **説明**: Zig 0.16.x をターゲットとする。mise でバージョン管理。
- **受入条件**:
  - [ ] Zig 0.16.x でビルド・テストが通る
  - [ ] `.mise.toml` に Zig バージョンが明記されている
- **依存要件**: なし

## REQ-INFRA-002: Zig package 配布

- **優先度**: Must
- **ステータス**: Draft
- **説明**: `build.zig.zon` でパッケージ情報を定義し、`zig fetch --save` で依存追加できる。
- **受入条件**:
  - [ ] `build.zig.zon` にパッケージ名・バージョン・依存情報が記載されている
  - [ ] `build.zig` で `addModule` によるライブラリ公開が行われている
  - [ ] ユーザーが `zig fetch --save <url>` で依存追加できる
  - [ ] 利用例が README に記載されている
- **依存要件**: なし

## REQ-INFRA-003: mise タスク構成

- **優先度**: Must
- **ステータス**: Draft
- **説明**: mise をタスクランナーとして使用し、主要な開発操作をタスク化する。
- **受入条件**:
  - [ ] `mise run build` — ライブラリのビルド
  - [ ] `mise run test` — ユニットテスト実行
  - [ ] `mise run bench` — ベンチマーク実行
  - [ ] `mise run fuzz` — ファズテスト実行
  - [ ] `mise run lint` — 静的解析
  - [ ] `mise run fmt` — コードフォーマット
  - [ ] `mise run clean` — ビルド成果物のクリーン
- **依存要件**: なし

## REQ-INFRA-004: GitHub Actions CI

- **優先度**: Must
- **ステータス**: Draft
- **説明**: PR ごとに自動テストを実行する CI パイプラインを構築する。
- **受入条件**:
  - [ ] PR 作成時・更新時に自動実行される
  - [ ] Zig 0.16.x でのビルド
  - [ ] テスト、lint、fmt チェックが含まれる
  - [ ] ベンチマーク結果がCIログに出力される
  - [ ] Linux, macOS でのクロスプラットフォームテスト
- **依存要件**: REQ-INFRA-001

## REQ-INFRA-005: ファズテスト

- **優先度**: Should
- **ステータス**: Draft
- **説明**: 任意のバイト列を入力としてクラッシュしないことを検証するファズテスト。Zig の built-in fuzz testing 機能を使用。
- **受入条件**:
  - [ ] 任意のバイト列入力で Lexer がクラッシュしない
  - [ ] 任意の正規表現パターン文字列で comptime DFA 生成がクラッシュしない
  - [ ] `mise run fuzz` で実行できる
  - [ ] CI で短時間（数分）のファズ実行が含まれる
- **依存要件**: REQ-CORE-001, REQ-REGEX-003
