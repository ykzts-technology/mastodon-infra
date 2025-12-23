# Mastodon Helm移行 - 事前チェックリスト

このチェックリストは、Kustomize管理からHelm Chart管理への移行を安全に実施するための事前確認項目です。

## 📋 環境準備

### ツールのバージョン確認

- [ ] Helm 3.11以上がインストールされている
  ```bash
  helm version
  # Expected: v3.11.0 or higher
  ```

- [ ] kubectl が正しく設定されている
  ```bash
  kubectl version
  kubectl cluster-info
  ```

- [ ] 適切なKubernetesコンテキストに接続している
  ```bash
  kubectl config current-context
  # Expected: gke_[project]_[region]_mastodon-cluster
  ```

- [ ] 必要な権限がある（管理者権限）
  ```bash
  kubectl auth can-i create deployments
  kubectl auth can-i delete deployments
  kubectl auth can-i create ingress
  ```

### Helm Repositoryの設定

- [ ] Mastodon Helm repositoryを追加済み
  ```bash
  helm repo add mastodon https://mastodon.github.io/helm-charts/
  helm repo update
  ```

- [ ] Mastodon chartが利用可能
  ```bash
  helm search repo mastodon/mastodon
  ```

## 🔐 Secrets管理の確認

### 既存Secretsの確認

- [ ] `mastodon` Secretが存在する
  ```bash
  kubectl get secret mastodon
  ```

- [ ] 必須キーがすべて含まれている
  ```bash
  kubectl get secret mastodon -o jsonpath='{.data}' | jq 'keys'
  ```

必須キーの一覧：
- [ ] SECRET_KEY_BASE
- [ ] VAPID_PRIVATE_KEY
- [ ] VAPID_PUBLIC_KEY
- [ ] ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
- [ ] ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
- [ ] ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
- [ ] DB_HOST
- [ ] DB_USER
- [ ] DB_PASS
- [ ] REDIS_HOST
- [ ] REDIS_PASSWORD
- [ ] AWS_ACCESS_KEY_ID (S3/GCS用)
- [ ] AWS_SECRET_ACCESS_KEY (S3/GCS用)
- [ ] SMTP_LOGIN
- [ ] SMTP_PASSWORD
- [ ] DEEPL_API_KEY
- [ ] ES_HOST (Elasticsearch)
- [ ] ES_USER (Elasticsearch)
- [ ] ES_PASS (Elasticsearch)

### Secretsのバックアップ

- [ ] Secretsをバックアップ（安全な場所に保管）
  ```bash
  mkdir -p backup
  kubectl get secret mastodon -o yaml > backup/mastodon-secret.yaml
  ```

## 📊 現行リソースの確認

### Deployment状態

- [ ] すべてのDeploymentが正常稼働中
  ```bash
  kubectl get deployments
  # mastodon-web, mastodon-streaming, mastodon-worker, manael
  ```

- [ ] すべてのPodがReady状態
  ```bash
  kubectl get pods
  ```

- [ ] PodのログにCRITICALエラーがない
  ```bash
  kubectl logs deployment/mastodon-web --tail=100
  kubectl logs deployment/mastodon-streaming --tail=100
  kubectl logs deployment/mastodon-worker --tail=100
  ```

### Service状態

- [ ] すべてのServiceが存在する
  ```bash
  kubectl get services
  # mastodon-web, mastodon-streaming, mastodon-assets, mastodon-emoji, manael
  ```

- [ ] EndpointsがServiceに紐づいている
  ```bash
  kubectl get endpoints
  ```

### Ingress状態

- [ ] Ingressが正常稼働中
  ```bash
  kubectl get ingress mastodon
  ```

- [ ] GCP Load BalancerのIPアドレスが割り当てられている
  ```bash
  kubectl get ingress mastodon -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
  ```

- [ ] SSL証明書が有効
  ```bash
  kubectl get managedcertificate mastodon-certificate
  ```

### HPA状態

- [ ] HPAが正常稼働中
  ```bash
  kubectl get hpa
  ```

- [ ] スケーリングが正常に動作している
  ```bash
  kubectl describe hpa mastodon-web
  kubectl describe hpa mastodon-streaming
  kubectl describe hpa mastodon-worker
  kubectl describe hpa manael
  ```

### ConfigMap確認

- [ ] mastodon-env ConfigMapが存在する
  ```bash
  kubectl get configmap mastodon-env
  ```

- [ ] 設定値を確認
  ```bash
  kubectl get configmap mastodon-env -o yaml
  ```

## 💾 データベースとバックアップ

### PostgreSQL

- [ ] データベースが正常稼働中
  ```bash
  kubectl exec deployment/mastodon-web -- bundle exec rails db:version
  ```

- [ ] データベース接続が正常
  ```bash
  kubectl exec deployment/mastodon-web -- bundle exec rails runner 'puts ActiveRecord::Base.connection.active?'
  ```

- [ ] Cloud SQLバックアップを手動取得
  ```bash
  gcloud sql backups create \
    --instance=mastodon-db \
    --project=YOUR_PROJECT_ID
  ```

- [ ] バックアップの完了を確認
  ```bash
  gcloud sql backups list --instance=mastodon-db --limit=1
  ```

### Redis

- [ ] Redis接続が正常
  ```bash
  kubectl exec deployment/mastodon-web -- bundle exec rails runner 'puts Redis.new.ping'
  ```

## 🗂️ 現行マニフェストのバックアップ

### Kubernetesリソースのエクスポート

- [ ] Deploymentsをバックアップ
  ```bash
  mkdir -p backup
  kubectl get deployment mastodon-web -o yaml > backup/deployment-mastodon-web.yaml
  kubectl get deployment mastodon-streaming -o yaml > backup/deployment-mastodon-streaming.yaml
  kubectl get deployment mastodon-worker -o yaml > backup/deployment-mastodon-worker.yaml
  kubectl get deployment manael -o yaml > backup/deployment-manael.yaml
  ```

- [ ] Servicesをバックアップ
  ```bash
  kubectl get service mastodon-web -o yaml > backup/service-mastodon-web.yaml
  kubectl get service mastodon-streaming -o yaml > backup/service-mastodon-streaming.yaml
  kubectl get service mastodon-assets -o yaml > backup/service-mastodon-assets.yaml
  kubectl get service mastodon-emoji -o yaml > backup/service-mastodon-emoji.yaml
  kubectl get service manael -o yaml > backup/service-manael.yaml
  ```

- [ ] Ingressをバックアップ
  ```bash
  kubectl get ingress mastodon -o yaml > backup/ingress-mastodon.yaml
  ```

- [ ] HPAをバックアップ
  ```bash
  kubectl get hpa -o yaml > backup/hpa-all.yaml
  ```

- [ ] ConfigMapをバックアップ
  ```bash
  kubectl get configmap mastodon-env -o yaml > backup/configmap-mastodon-env.yaml
  ```

- [ ] GCP固有リソースをバックアップ
  ```bash
  kubectl get backendconfig -o yaml > backup/backendconfig.yaml
  kubectl get frontendconfig -o yaml > backup/frontendconfig.yaml
  kubectl get managedcertificate -o yaml > backup/managedcertificate.yaml
  ```

## 📝 values.yamlの準備

### Helm values.yamlのカスタマイズ

- [ ] `helm/values-production.yaml`を環境に合わせて編集
  - [ ] ドメイン名を設定 (`mastodon.localDomain`)
  - [ ] Secret参照を設定 (`mastodon.secrets.existingSecret`)
  - [ ] PostgreSQL接続情報を設定
  - [ ] Redis接続情報を設定
  - [ ] S3/GCS設定を確認
  - [ ] SMTP設定を確認
  - [ ] リソース制限を確認
  - [ ] NodeSelectorを確認（GKE Spot instances）

### values.yamlの検証

- [ ] values.yamlのYAML文法が正しい
  ```bash
  cat helm/values-production.yaml | yq eval '.' -
  ```

- [ ] Helmテンプレートのレンダリングテスト
  ```bash
  helm template mastodon mastodon/mastodon \
    --values helm/values-production.yaml \
    --debug
  ```

## 🧪 ステージング環境でのテスト（推奨）

- [ ] テスト用Namespaceを作成
  ```bash
  kubectl create namespace mastodon-helm-test
  ```

- [ ] Secretsをテスト用Namespaceにコピー
  ```bash
  kubectl get secret mastodon -o yaml | \
    sed 's/namespace: default/namespace: mastodon-helm-test/' | \
    kubectl apply -f -
  ```

- [ ] Helm chartをテスト環境にインストール
  ```bash
  helm install mastodon-test mastodon/mastodon \
    --namespace mastodon-helm-test \
    --values helm/values-production.yaml
  ```

- [ ] テスト環境でPodが起動することを確認
  ```bash
  kubectl get pods -n mastodon-helm-test
  ```

- [ ] テスト環境でヘルスチェックが成功
  ```bash
  kubectl exec -n mastodon-helm-test deployment/mastodon-test-web -- \
    curl -f http://localhost:3000/health
  ```

- [ ] テスト環境をクリーンアップ
  ```bash
  helm uninstall mastodon-test -n mastodon-helm-test
  kubectl delete namespace mastodon-helm-test
  ```

## 👥 コミュニケーション

### ユーザーへの告知

- [ ] メンテナンス予定を事前告知（最低24時間前）
- [ ] メンテナンス時間の見積もりを共有（推奨: 1-2時間）
- [ ] 緊急連絡先を確認

### チーム内連絡

- [ ] 移行作業の責任者を決定
- [ ] ロールバック権限を持つメンバーを確認
- [ ] 移行中の連絡手段を確認（Slack/Discord等）

## 📅 スケジューリング

### タイミングの選択

- [ ] トラフィックが少ない時間帯を選択
- [ ] 十分な作業時間を確保（最低2-3時間）
- [ ] 翌日に問題対応できる体制を確認

### 移行日時の決定

**重要**: 以下のフィールドを記入してから移行作業を開始してください。

- [ ] 移行予定日時: ____年__月__日 __:__ (JST) ← 記入必須
- [ ] 移行担当者: ________________ ← 記入必須
- [ ] バックアップ担当者: ________________ ← 記入必須

## 🚨 緊急時の準備

### ロールバック計画

- [ ] ロールバック手順を確認
- [ ] ロールバックに必要な時間を見積もり（推奨: 15-30分）
- [ ] ロールバック実施の判断基準を決定

### モニタリング準備

- [ ] Grafanaダッシュボードを開いておく
- [ ] GCPコンソールを開いておく
- [ ] kubectl / helm コマンドをすぐ実行できる状態にしておく

## ✅ 最終確認

- [ ] すべてのチェック項目を完了した
- [ ] バックアップがすべて取得済み
- [ ] ロールバック手順を理解している
- [ ] 移行作業のタイムラインを理解している
- [ ] 問題発生時の連絡体制を理解している

## 📞 サポート連絡先

- インフラ担当: ________________
- アプリケーション担当: ________________
- 緊急連絡先: ________________

---

**注意**: このチェックリストのすべての項目を完了してから、本番環境への移行作業を開始してください。
