# Mastodon Kustomize → Helm Chart 移行ガイド

## 概要

このドキュメントは、現在Kustomizeで管理しているMastodonのKubernetesマニフェストを、Mastodon公式Helm Chartへ移行する手順を記載します。

## 移行の目的

- 運用の簡素化: Helm Chartによる標準化されたデプロイメント管理
- アップグレードの容易性: Helm releaseを利用した更新とロールバック
- ベストプラクティスの適用: Mastodon公式が推奨する構成の採用
- 保守性の向上: values.yamlによる集中的な設定管理

## 前提条件

- Helmクライアント v3.11以上がインストールされていること
- kubectlでGKEクラスタへの接続が設定されていること
- 既存のKustomize構成が稼働中であること
- 必要な権限（Deployment、Service、Ingress等の作成・削除）があること

## アーキテクチャの比較

### 現在の構成（Kustomize）
```
k8s/
├── base/
│   ├── mastodon-web/
│   ├── mastodon-streaming/
│   ├── mastodon-worker/
│   ├── manael/
│   ├── configmap.yaml
│   └── ingress.yaml
└── overlays/
    └── production/
        ├── patches/
        ├── hpa.yaml
        └── kustomization.yaml
```

### 移行後の構成（Helm）
```
helm/
├── values-production.yaml    # 本番環境設定
└── Chart.yaml                # Helm chart参照（オプション）
```

## 設定のマッピング

### 環境変数（ConfigMap → Helm values）

| Kustomize (ConfigMap) | Helm values.yaml |
|----------------------|------------------|
| `DEFAULT_LOCALE: ja` | `mastodon.locale: ja` |
| `SINGLE_USER_MODE: "true"` | `mastodon.singleUserMode: true` |
| `LOCAL_DOMAIN: ykzts.technology` | `mastodon.localDomain: ykzts.technology` |
| `WEB_CONCURRENCY: "3"` | `mastodon.web.workers: "3"` |
| `MAX_THREADS: "10"` | `mastodon.web.maxThreads: "10"` |

### リソース設定

| Component | Kustomize | Helm values path |
|-----------|-----------|-----------------|
| Web | `memory: 1.5Gi, cpu: 1` | `mastodon.web.resources` |
| Streaming | `memory: 512Mi, cpu: 0.5` | `mastodon.streaming.resources` |
| Worker | `memory: 1Gi, cpu: 0.5` | `mastodon.sidekiq.workers[0].resources` |

### HPA設定

現在のHPA設定は、Helm chart外で継続管理するか、または別途HPAマニフェストとして適用します。

## 移行手順（ダウンタイム最小化）

### Phase 1: 準備フェーズ

#### 1.1 現行設定のバックアップ

```bash
# 現在のマニフェストをバックアップ
kubectl get all -n default -l app=mastodon-web -o yaml > backup/mastodon-web.yaml
kubectl get all -n default -l app=mastodon-streaming -o yaml > backup/mastodon-streaming.yaml
kubectl get all -n default -l app=mastodon-worker -o yaml > backup/mastodon-worker.yaml
kubectl get configmap mastodon-env -o yaml > backup/mastodon-configmap.yaml
kubectl get secret mastodon -o yaml > backup/mastodon-secret.yaml
kubectl get ingress mastodon -o yaml > backup/mastodon-ingress.yaml
kubectl get hpa -o yaml > backup/mastodon-hpa.yaml
```

#### 1.2 Helm Repositoryの追加

```bash
helm repo add mastodon https://mastodon.github.io/helm-charts/
helm repo update
```

#### 1.3 Secretsの確認

既存のKubernetes Secretsが正しく設定されているか確認します：

```bash
kubectl get secret mastodon -o jsonpath='{.data}' | jq 'keys'
```

必要なキー:
- SECRET_KEY_BASE
- VAPID_PRIVATE_KEY / VAPID_PUBLIC_KEY
- ACTIVE_RECORD_ENCRYPTION_* (3種類)
- DB_USER / DB_PASS / DB_HOST
- REDIS_PASSWORD / REDIS_HOST
- AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (S3用)
- SMTP_LOGIN / SMTP_PASSWORD
- DEEPL_API_KEY
- ES_HOST / ES_USER / ES_PASS (Elasticsearch)

#### 1.4 values.yamlのカスタマイズ

`helm/values-production.yaml`を環境に合わせて調整します。特に以下を確認：

- PostgreSQLとRedisのホスト名
- Elasticsearchの接続情報
- S3/GCS設定
- ドメイン名とIngress設定

### Phase 2: ステージング環境での検証（推奨）

#### 2.1 別Namespaceへのテストデプロイ

```bash
# テスト用Namespaceの作成
kubectl create namespace mastodon-helm-test

# Secretsをテスト用Namespaceにコピー
kubectl get secret mastodon -o yaml | \
  sed 's/namespace: default/namespace: mastodon-helm-test/' | \
  kubectl apply -f -

# Helm chartのインストール（dry-run）
helm install mastodon-test mastodon/mastodon \
  --namespace mastodon-helm-test \
  --values helm/values-production.yaml \
  --dry-run --debug

# 実際のインストール
helm install mastodon-test mastodon/mastodon \
  --namespace mastodon-helm-test \
  --values helm/values-production.yaml
```

#### 2.2 動作確認

```bash
# Podの状態確認
kubectl get pods -n mastodon-helm-test

# ログ確認
kubectl logs -n mastodon-helm-test deployment/mastodon-test-web

# データベース接続テスト
kubectl exec -n mastodon-helm-test deployment/mastodon-test-web -it -- \
  bundle exec rails db:version
```

#### 2.3 問題があれば修正して再テスト

```bash
# Helm releaseの削除
helm uninstall mastodon-test -n mastodon-helm-test

# values.yamlを修正後、再インストール
helm install mastodon-test mastodon/mastodon \
  --namespace mastodon-helm-test \
  --values helm/values-production.yaml
```

### Phase 3: 本番環境への移行

**重要**: 以下の手順は本番環境でのダウンタイムを最小化しますが、完全にゼロダウンタイムを保証するものではありません。メンテナンス時間の確保を推奨します。

#### 3.1 メンテナンスモードの設定（オプション）

ユーザーへの影響を最小化するため、事前に告知を行います。

#### 3.2 データベースのバックアップ

```bash
# Cloud SQLのバックアップを手動で取得
gcloud sql backups create \
  --instance=mastodon-db \
  --project=your-project-id
```

#### 3.3 既存リソースへのラベル追加

Helmとの衝突を避けるため、既存リソースにラベルを追加します：

```bash
# Kustomize管理であることを明示
kubectl label deployment mastodon-web managed-by=kustomize
kubectl label deployment mastodon-streaming managed-by=kustomize
kubectl label deployment mastodon-worker managed-by=kustomize
kubectl label service mastodon-web managed-by=kustomize
kubectl label service mastodon-streaming managed-by=kustomize
```

#### 3.4 Helm Chartのインストール（並行稼働）

Helm chartを異なるリソース名でデプロイします：

```bash
# Helm releaseのインストール
helm install mastodon-helm mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml \
  --set nameOverride=mastodon-helm \
  --timeout 10m
```

この時点で以下のリソースが並行稼働します：
- Kustomize管理: mastodon-web, mastodon-streaming, mastodon-worker
- Helm管理: mastodon-helm-web, mastodon-helm-streaming, mastodon-helm-sidekiq

#### 3.5 新しいデプロイメントの動作確認

```bash
# Helm管理のPodが正常に起動しているか確認
kubectl get pods -l app.kubernetes.io/instance=mastodon-helm

# ログ確認
kubectl logs deployment/mastodon-helm-web -f

# ヘルスチェック
kubectl exec deployment/mastodon-helm-web -- curl -f http://localhost:3000/health
```

#### 3.6 Ingressの切り替え

Ingressを更新して、新しいHelm管理のServiceへトラフィックを向けます：

```bash
# 現在のIngressをバックアップ
kubectl get ingress mastodon -o yaml > backup/ingress-before-migration.yaml

# Ingressの削除（Helm chartが自動作成するため）
kubectl delete ingress mastodon

# Helm chartによるIngressの確認
kubectl get ingress mastodon-helm

# 必要に応じてGCP固有のアノテーションを追加
kubectl annotate ingress mastodon-helm \
  networking.gke.io/managed-certificates=mastodon-certificate
```

#### 3.7 トラフィックの監視

```bash
# アクセスログの確認
kubectl logs -f deployment/mastodon-helm-web

# エラーレートの監視（Grafana等）
# 数分間監視し、問題がないことを確認
```

#### 3.8 旧リソースの削除

新しいデプロイメントが正常に動作していることを確認したら、旧リソースを削除します：

```bash
# Kustomize管理のリソースを削除
kubectl delete -k k8s/overlays/production

# 手動で残っているリソースを確認
kubectl get all -l managed-by=kustomize

# 残っていれば個別に削除
kubectl delete deployment mastodon-web mastodon-streaming mastodon-worker
kubectl delete service mastodon-web mastodon-streaming
```

#### 3.9 Helm管理リソースの名前変更（オプション）

並行稼働用に付けた名前を元に戻す場合：

```bash
# 一度アンインストール
helm uninstall mastodon-helm

# 標準的な名前で再インストール
helm install mastodon mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml

# または、Skaffoldを使用
skaffold run -p helm-production
```

### Phase 4: HPAとモニタリングの再設定

#### 4.1 HPA設定の適用

既存のHPA設定を新しいデプロイメント名に合わせて適用します：

```bash
# HPA設定を編集して新しいdeployment名を指定
# mastodon-web → mastodon-helm-web (または mastodon-web)
kubectl apply -f k8s/overlays/production/hpa.yaml
```

または、Helm values.yamlに統合します（将来的な改善として）。

#### 4.2 GCP BackendConfigとFrontendConfigの再適用

```bash
kubectl apply -f k8s/overlays/production/backendconfig.yaml
kubectl apply -f k8s/overlays/production/frontendconfig.yaml

# Serviceアノテーションの追加
kubectl annotate service mastodon-helm-web \
  beta.cloud.google.com/backend-config='{"default": "mastodon-web-backend-config"}'
```

#### 4.3 Monitoring設定の更新

```bash
# PodMonitoring CRDを更新
kubectl apply -f k8s/overlays/production/monitoring.yaml
```

### Phase 5: Manaelの対応

Manael（メディアプロキシ）はHelm chartに含まれていないため、別途デプロイメントとして継続管理します。

```bash
# Manaelはそのまま維持
kubectl get deployment manael
kubectl get service manael

# 必要に応じてIngress設定でmanaelへのルーティングを確認
```

将来的には、別のHelm chartとして管理するか、values.yamlに追加コンポーネントとして統合することを検討します。

## ロールバック手順

移行後に問題が発生した場合のロールバック手順：

### 緊急ロールバック（Ingressのみ切り戻し）

```bash
# Ingressを旧Serviceに向け直す
kubectl apply -f backup/ingress-before-migration.yaml

# 旧Kustomize管理のDeploymentがまだ残っている場合
kubectl get deployment mastodon-web mastodon-streaming mastodon-worker
# 残っていれば、すぐにトラフィックが流れる
```

### 完全ロールバック

```bash
# Helm releaseの削除
helm uninstall mastodon-helm

# Kustomize設定の再適用
kubectl apply -k k8s/overlays/production

# Ingressの復元
kubectl apply -f backup/ingress-before-migration.yaml

# HPA、BackendConfig等の復元
kubectl apply -f backup/mastodon-hpa.yaml
kubectl apply -f k8s/overlays/production/backendconfig.yaml
```

### データベースのロールバック（最終手段）

```bash
# Cloud SQLバックアップからの復元
gcloud sql backups restore [BACKUP_ID] \
  --backup-instance=mastodon-db \
  --project=your-project-id
```

## 移行後の運用

### デプロイメントの更新

**Helmコマンドを直接使用:**

```bash
# values.yamlの編集後
helm upgrade mastodon mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml

# 特定のイメージタグの更新
helm upgrade mastodon mastodon/mastodon \
  --namespace default \
  --values helm/values-production.yaml \
  --set image.tag=v4.5.2
```

**Skaffoldを使用（推奨）:**

```bash
# 本番環境へデプロイ
skaffold run -p helm-production

# 継続的な開発モード
skaffold dev -p helm-dev

# デプロイメントの削除
skaffold delete -p helm-production
```

### ロールバック

**Helmコマンドを直接使用:**

```bash
# 前のリビジョンへのロールバック
helm rollback mastodon

# 特定のリビジョンへのロールバック
helm rollback mastodon 2
```

**Skaffoldを使用:**

Skaffoldは直接的なロールバック機能を提供しないため、以下の方法を使用：

```bash
# values.yamlを前のバージョンに戻してから再デプロイ
git checkout <previous-commit> -- helm/values-production.yaml
skaffold run -p helm-production

# または、Helmコマンドを直接使用してロールバック
helm rollback mastodon
```

### リリース履歴の確認

```bash
helm history mastodon
```

### 設定の確認

```bash
# 現在の設定値を確認
helm get values mastodon

# すべての設定値を確認（デフォルト含む）
helm get values mastodon --all
```

## トラブルシューティング

### Podが起動しない

```bash
# Pod状態の確認
kubectl get pods -l app.kubernetes.io/instance=mastodon

# イベント確認
kubectl describe pod [POD_NAME]

# ログ確認
kubectl logs [POD_NAME]
```

### データベース接続エラー

```bash
# Secret設定の確認
kubectl get secret mastodon -o yaml

# 環境変数の確認
kubectl exec deployment/mastodon-helm-web -- env | grep -E '(DB_|POSTGRES_)'

# データベース接続テスト
kubectl exec deployment/mastodon-helm-web -it -- \
  bundle exec rails db:version
```

### S3/GCS接続エラー

```bash
# S3設定の確認
kubectl exec deployment/mastodon-helm-web -- env | grep -E '(S3_|AWS_)'

# 接続テスト
kubectl exec deployment/mastodon-helm-web -it -- \
  bundle exec rails console
# Mastodon console内で:
# Paperclip::Attachment.default_options[:storage]
```

### Ingress/ロードバランサの問題

```bash
# Ingress状態の確認
kubectl describe ingress mastodon-helm

# GCPロードバランサの確認
gcloud compute forwarding-rules list
gcloud compute backend-services list

# SSL証明書の確認
kubectl get managedcertificate
```

## チェックリスト

移行前に以下を確認してください：

### 準備段階
- [ ] 既存リソースのバックアップを取得
- [ ] データベースのバックアップを取得
- [ ] すべての Secret が正しく設定されている
- [ ] values-production.yaml を環境に合わせてカスタマイズ
- [ ] ステージング環境でテスト完了（推奨）
- [ ] メンテナンス時間を確保
- [ ] ユーザーへの事前告知

### 移行中
- [ ] Helm chart が正常にインストールされた
- [ ] 新しい Pod がすべて Running 状態
- [ ] ヘルスチェックが成功
- [ ] データベース接続が正常
- [ ] Redis 接続が正常
- [ ] S3/GCS 接続が正常
- [ ] Ingress が正しく設定されている

### 移行後
- [ ] トラフィックが新しい Pod に流れている
- [ ] エラーログが増加していない
- [ ] ユーザーアクセスが正常
- [ ] メディアアップロードが動作
- [ ] バックグラウンドジョブが処理されている
- [ ] HPA が正常に動作
- [ ] モニタリングが正常
- [ ] 旧リソースをクリーンアップ

## 参考リンク

- [Mastodon公式Helm Chart](https://github.com/mastodon/helm-charts)
- [Mastodon公式ドキュメント](https://docs.joinmastodon.org/)
- [Helm公式ドキュメント](https://helm.sh/docs/)
- [GKE Ingress設定](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress)

## サポート

問題が発生した場合は、以下を確認してください：

1. このドキュメントのトラブルシューティングセクション
2. Helm chart の公式ドキュメント
3. GitHubリポジトリのIssue

緊急時は、ロールバック手順に従って旧構成に戻してください。
