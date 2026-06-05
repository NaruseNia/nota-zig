# TASK-012: GitHub Actions CI

- **関連要件**: REQ-INFRA-004
- **規模**: S
- **依存タスク**: TASK-001

## 実装概要

PR ごとに自動テスト・lint・フォーマットチェックを実行する GitHub Actions ワークフローを構築する。

## 対象ファイル

- `.github/workflows/ci.yml`

## 実装ステップ

1. ワークフロー定義:
   - トリガー: `push` (main), `pull_request`
   - マトリクス: Zig 0.16.x
   - OS: ubuntu-latest, macos-latest
2. ジョブ構成:
   - `test`: `zig build test`
   - `lint`: Zig の静的解析
   - `fmt-check`: `zig fmt --check src/`
   - `bench`: ベンチマーク実行（結果をログ出力）
   - `fuzz`: 短時間ファズ実行（2分）
3. mise を CI でインストールして使用する、または zig コマンドを直接使用するかを判断
4. キャッシュ: `zig-cache/` をキャッシュして CI 高速化
