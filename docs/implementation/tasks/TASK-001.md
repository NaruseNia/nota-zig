# TASK-001: プロジェクト基盤セットアップ

- **関連要件**: REQ-INFRA-001, REQ-INFRA-002, REQ-INFRA-003
- **規模**: S
- **依存タスク**: なし

## 実装概要

Zig プロジェクトの初期構造を作成する。build.zig, build.zig.zon, .mise.toml, .gitignore, LICENSE, README.md を配置。

## 対象ファイル

- `build.zig`
- `build.zig.zon`
- `.mise.toml`
- `.gitignore`
- `LICENSE`
- `README.md`
- `src/nota.zig` (空のエントリポイント)

## 実装ステップ

1. `build.zig.zon` にパッケージメタデータ（名前: "nota", バージョン: "0.1.0"）を記述
2. `build.zig` でライブラリモジュール公開 + テストステップ定義
3. `.mise.toml` に Zig バージョン (0.16.0) と 7 タスク (build, test, bench, fuzz, lint, fmt, clean) を定義
4. `.gitignore` に `zig-out/`, `zig-cache/`, `.zig-cache/` を追加
5. MIT LICENSE ファイルを作成
6. 最小限の README.md を作成
7. `src/nota.zig` に空の公開モジュールを作成
8. `mise run build` と `mise run test` が正常に動作することを確認
