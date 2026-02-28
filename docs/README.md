# Mastodon Helm Migration Documentation

このディレクトリには、MastodonをKustomize管理から公式Helm Chart管理へ移行するための完全なドキュメントが含まれています。

## 📚 ドキュメント一覧

### 0. [Skaffold + Helm Usage Guide](./skaffold-helm-usage.md) 🆕
**Skaffoldを使った簡単なデプロイメント** - SkaffoldとHelm Chartを組み合わせて使用する方法を説明します。

**内容**:
- Skaffoldプロファイルの説明（Kustomize/Helm対応）
- 基本的な使い方とコマンド例
- 開発モード（継続的デプロイ）の使用方法
- CI/CDへの統合例
- トラブルシューティング

**対象者**: 開発者、インフラエンジニア、CI/CD担当者

**推奨読了時間**: 15分

**使い方**: Helm移行後の日常的なデプロイメント作業で参照してください。

---

### 1. [Helm Migration Guide](./helm-migration-guide.md)
**最も重要なドキュメント** - Kustomize管理からHelm Chart管理への移行手順を段階的に説明します。

**内容**:
- 移行の目的と背景
- 設定のマッピング方法
- 5つのPhaseに分けた詳細な移行手順
- ステージング環境でのテスト方法
- 本番環境への適用手順（ダウンタイム最小化）
- トラブルシューティング

**対象者**: インフラエンジニア、移行作業担当者

**推奨読了時間**: 30分

---

### 2. [Pre-Migration Checklist](./pre-migration-checklist.md)
移行前に確認すべきすべての項目をチェックリスト形式でまとめています。

**内容**:
- 環境準備の確認
- Secrets管理の確認
- 現行リソースの状態確認
- データベースとバックアップの確認
- マニフェストのバックアップ手順
- values.yamlの準備と検証
- ステージング環境でのテスト
- コミュニケーション計画
- 緊急時の準備

**対象者**: 移行作業担当者、レビュアー

**推奨読了時間**: 20分

**使い方**: 移行作業前に、すべての項目にチェックを入れて確認してください。

---

### 3. [Downtime Minimization Strategy](./downtime-minimization-strategy.md)
ダウンタイムを最小化するための3つの戦略を詳しく解説します。

**内容**:
- 戦略1: Blue-Green デプロイメント（推奨、ダウンタイム最小）
- 戦略2: Rolling Update方式（コスト効率的）
- 戦略3: メンテナンスモード方式（最も安全）
- ダウンタイム発生の主な原因と対策
- 推奨戦略の選択基準
- ロールバック時のダウンタイム最小化
- モニタリングとアラート設定

**対象者**: インフラエンジニア、アーキテクト

**推奨読了時間**: 25分

**特に重要**: 各戦略の「想定ダウンタイム」を確認し、要件に合った戦略を選択してください。

---

### 4. [Rollback Procedure](./rollback-procedure.md)
移行後に問題が発生した場合の緊急ロールバック手順を記載しています。

**内容**:
- ロールバックの判断基準（Critical/High/Medium）
- 3つのロールバックレベル
  - Level 1: Ingressのみ切り戻し（1-2分）
  - Level 2: Helmリリース削除と旧環境復元（5-10分）
  - Level 3: データベースのロールバック（30分-2時間）
- 詳細な手順とコマンド
- トラブルシューティング
- ロールバック後の対応

**対象者**: 移行作業担当者、オンコールエンジニア

**推奨読了時間**: 20分

**重要**: 移行前に必ず一読し、緊急時にすぐ参照できるようにしてください。

---

## 🚀 クイックスタートガイド

### 初めて移行を検討する方

1. **[Helm Migration Guide](./helm-migration-guide.md)** を最初に読む
2. **[Downtime Minimization Strategy](./downtime-minimization-strategy.md)** で適切な戦略を選択
3. **[Pre-Migration Checklist](./pre-migration-checklist.md)** を印刷またはコピーして準備開始
4. **[Rollback Procedure](./rollback-procedure.md)** を理解し、緊急時に備える

### 移行作業を実施する方

1. **[Pre-Migration Checklist](./pre-migration-checklist.md)** のすべての項目を確認
2. **[Helm Migration Guide](./helm-migration-guide.md)** の手順に従って作業
3. 問題発生時は **[Rollback Procedure](./rollback-procedure.md)** を参照

### 移行後のトラブル対応

1. **[Rollback Procedure](./rollback-procedure.md)** で適切なレベルを選択
2. **[Helm Migration Guide](./helm-migration-guide.md)** のトラブルシューティングセクションを参照

---

## 📋 移行作業の全体フロー

```
準備段階
├── Helm Migration Guide を読む
├── Pre-Migration Checklist で準備
└── Downtime Minimization Strategy で戦略選択
    ↓
ステージング環境でのテスト（推奨）
├── テスト用Namespaceでデプロイ
├── 動作確認
└── 問題があれば修正
    ↓
本番環境への移行
├── バックアップ取得
├── 選択した戦略で移行実施
├── 動作確認
└── 問題があれば Rollback Procedure を実行
    ↓
移行完了
├── 旧リソースのクリーンアップ
├── モニタリングの継続
└── ドキュメントの更新
```

---

## 💡 重要なポイント

### ✅ Do's（推奨事項）

- 必ずステージング環境でテストしてから本番適用する
- すべてのバックアップを取得する
- Pre-Migration Checklistのすべての項目を確認する
- 移行作業は、トラフィックが少ない時間帯に実施する
- 十分な作業時間を確保する（最低2-3時間）
- Rollback Procedureを事前に理解しておく
- 移行中はモニタリングを継続する

### ❌ Don'ts（禁止事項）

- バックアップなしで移行作業を開始しない
- チェックリストを飛ばして作業しない
- テストなしに本番環境で初めて試さない
- 移行中に別の変更を同時に行わない
- ロールバック手順を理解せずに作業しない
- 問題発生時に判断を遅らせない

---

## 🔧 使用するツール

- **Helm**: v3.11以上
- **kubectl**: クラスタバージョンに対応したもの
- **gcloud**: GCP CLI（Cloud SQL操作用）
- **yq**: YAML検証用（オプション）

---

## 📞 サポート

問題が発生した場合は:

1. まず該当するドキュメントのトラブルシューティングセクションを確認
2. Rollback Procedureで迅速にロールバック
3. 問題を記録し、後日原因分析

緊急時の連絡先をPre-Migration Checklistに記載してください。

---

## 📝 フィードバック

これらのドキュメントは、実際の移行作業を通じて改善していくことを想定しています。

- 不明瞭な点
- 追加すべき情報
- 改善提案

などがあれば、GitHubのIssueまたはPull Requestでお知らせください。

---

**最終更新**: 2025年11月24日  
**バージョン**: 1.0.0  
**対象Helmチャート**: mastodon/mastodon v0.2.3以降
