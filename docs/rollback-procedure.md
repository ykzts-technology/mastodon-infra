# ロールバック手順書

Helm移行後に問題が発生した場合のロールバック手順を記載します。

## ロールバックの判断基準

以下のいずれかに該当する場合、ロールバックを実施します：

### Critical（即座にロールバック）
- [ ] サービスが完全にダウンしている（5xx エラー率 > 50%）
- [ ] データベース接続が完全に失敗している
- [ ] ユーザーがログインできない
- [ ] 重大なセキュリティ問題が発見された

### High（15分以内にロールバック判断）
- [ ] 5xx エラー率が10%を超えている
- [ ] レスポンスタイムが通常の3倍以上
- [ ] バックグラウンドジョブが処理されていない
- [ ] メディアアップロードが失敗している

### Medium（30分以内にロールバック判断）
- [ ] 5xx エラー率が5%を超えている
- [ ] 一部機能が動作していない
- [ ] パフォーマンスが著しく低下している

## ロールバックレベル

状況に応じて適切なロールバックレベルを選択します。

### Level 1: Ingressのみ切り戻し（最速）

**所要時間**: 1-2分  
**適用場面**: Helm管理のPodは起動しているが、問題がある場合

```bash
# 旧環境がまだ残っている場合、スケールアップ
kubectl scale deployment mastodon-web --replicas=1
kubectl scale deployment mastodon-streaming --replicas=1
kubectl scale deployment mastodon-worker --replicas=1

# Podの起動を待つ（30秒-1分）
kubectl wait --for=condition=ready pod -l app=mastodon-web --timeout=60s

# Ingressを旧Serviceに戻す
kubectl apply -f backup/ingress-mastodon.yaml

# 新環境をスケールダウン（オプション）
kubectl scale deployment mastodon-helm-web --replicas=0
kubectl scale deployment mastodon-helm-streaming --replicas=0
kubectl scale deployment mastodon-helm-sidekiq-all-queues --replicas=0
```

### Level 2: Helmリリースの削除と旧環境の復元

**所要時間**: 5-10分  
**適用場面**: Helm管理のPodに問題があり、完全に戻す必要がある場合

```bash
# Helm releaseの削除
helm uninstall mastodon

# または特定のリリース名の場合
helm uninstall mastodon-helm

# 旧Kustomize構成の復元
kubectl apply -k k8s/overlays/production

# Podの起動を待つ
kubectl wait --for=condition=ready pod -l app=mastodon-web --timeout=300s

# Ingress、HPA等の復元
kubectl apply -f backup/ingress-mastodon.yaml
kubectl apply -f k8s/overlays/production/hpa.yaml

# GCP固有リソースの復元
kubectl apply -f k8s/overlays/production/backendconfig.yaml
kubectl apply -f k8s/overlays/production/frontendconfig.yaml

# サービスアノテーションの復元
kubectl annotate service mastodon-web \
  beta.cloud.google.com/backend-config='{"default": "mastodon-web-backend-config"}' \
  --overwrite
kubectl annotate service mastodon-streaming \
  beta.cloud.google.com/backend-config='{"default": "mastodon-streaming-backend-config"}' \
  --overwrite
```

### Level 3: データベースのロールバック（最終手段）

**所要時間**: 30分-2時間  
**適用場面**: データベースマイグレーションに問題があり、データが破損した場合

**警告**: このレベルのロールバックは、移行後に作成されたすべてのデータ（投稿、フォロー等）が失われます。

```bash
# 1. アプリケーションをすべて停止
kubectl scale deployment --all --replicas=0

# 2. Cloud SQLバックアップの一覧を確認
gcloud sql backups list --instance=mastodon-db --limit=5

# 3. 移行直前のバックアップを特定
# 例: BACKUP_ID=1234567890123

# 4. バックアップから復元
gcloud sql backups restore 1234567890123 \
  --backup-instance=mastodon-db \
  --project=YOUR_PROJECT_ID

# 5. 復元が完了するまで待つ（15-30分）
gcloud sql operations list --instance=mastodon-db --limit=1

# 6. 旧Kustomize構成でアプリケーションを再起動
kubectl apply -k k8s/overlays/production

# 7. 動作確認
kubectl exec deployment/mastodon-web -- bundle exec rails db:version
```

## 詳細手順

### 手順1: 状況の確認

```bash
# 現在のPod状態を確認
kubectl get pods

# エラーログを確認
kubectl logs deployment/mastodon-web --tail=100
kubectl logs deployment/mastodon-streaming --tail=100
kubectl logs deployment/mastodon-sidekiq-all-queues --tail=100

# Ingressの状態を確認
kubectl get ingress
kubectl describe ingress mastodon

# データベース接続を確認
kubectl exec deployment/mastodon-web -- \
  bundle exec rails runner 'puts ActiveRecord::Base.connection.active?'

# Redis接続を確認
kubectl exec deployment/mastodon-web -- \
  bundle exec rails runner 'puts Redis.new.ping'
```

### 手順2: ロールバックレベルの決定

上記の状況確認を基に、適切なロールバックレベルを選択します。

### 手順3: ロールバックの実行

選択したレベルに応じて、上記のコマンドを実行します。

### 手順4: 動作確認

```bash
# サービスが起動しているか確認
kubectl get pods

# ヘルスチェック
curl -I https://ykzts.technology/health

# ログイン動作確認（ブラウザから手動）
# https://ykzts.technology/

# バックグラウンドジョブの確認
kubectl logs deployment/mastodon-worker --tail=50

# エラーログの確認
kubectl logs deployment/mastodon-web --tail=100 | grep -i error
```

### 手順5: モニタリングの継続

ロールバック後、少なくとも30分間はシステムを監視します：

```bash
# エラーレートの監視
# Grafanaダッシュボードで確認

# Podの状態監視
watch kubectl get pods

# リソース使用量の監視
kubectl top pods
```

## ロールバック後の対応

### 即座に実施すること

1. **ユーザーへの告知**
   - 問題が発生したこと
   - ロールバックを実施したこと
   - 現在は正常稼働していること

2. **問題の記録**
   - エラーログの保存
   - スクリーンショットの取得
   - 発生時刻と対応内容の記録

3. **チーム内共有**
   - 問題の内容
   - ロールバック理由
   - 影響範囲

### 後日実施すること

1. **原因分析**
   - ログの詳細分析
   - 設定の見直し
   - テスト環境での再現

2. **再移行計画の策定**
   - 問題の修正
   - テスト手順の改善
   - 新しい移行日程の決定

3. **ドキュメントの更新**
   - 発見された問題点の追記
   - ロールバック手順の改善
   - チェックリストの更新

## トラブルシューティング

### 問題: 旧Deploymentが起動しない

```bash
# イメージが削除されていないか確認
kubectl describe pod mastodon-web-xxx

# ConfigMapとSecretが存在するか確認
kubectl get configmap mastodon-env
kubectl get secret mastodon

# ノードリソースを確認
kubectl top nodes

# 必要に応じてPodを手動削除して再作成
kubectl delete pod -l app=mastodon-web
```

### 問題: Ingressが更新されない

```bash
# Ingress Controllerのログを確認
kubectl logs -n kube-system deployment/ingress-nginx-controller

# GCP Load Balancerの状態を確認
gcloud compute forwarding-rules list
gcloud compute backend-services list

# IngressをいったんLBに削除して再作成
kubectl delete ingress mastodon
kubectl apply -f backup/ingress-mastodon.yaml
```

### 問題: データベース接続エラー

```bash
# Secretの内容を確認
kubectl get secret mastodon -o yaml

# 環境変数が正しくPodに渡されているか確認
kubectl exec deployment/mastodon-web -- env | grep DB

# Cloud SQLへの接続をテスト
kubectl exec deployment/mastodon-web -it -- \
  bundle exec rails dbconsole
```

### 問題: Redis接続エラー

```bash
# Redisホスト名とパスワードを確認
kubectl get secret mastodon -o jsonpath='{.data.REDIS_HOST}' | base64 -d
kubectl get secret mastodon -o jsonpath='{.data.REDIS_PASSWORD}' | base64 -d

# Redis接続をテスト
kubectl exec deployment/mastodon-web -it -- \
  bundle exec rails console
# >> Redis.new.ping
```

## チェックリスト

ロールバック実施時は以下を確認してください：

### 実施前
- [ ] ロールバック理由を明確にする
- [ ] ロールバックレベルを決定する
- [ ] チームメンバーに通知する
- [ ] 必要なバックアップファイルが存在する

### 実施中
- [ ] 各コマンドの実行結果を確認する
- [ ] エラーが発生したら即座に記録する
- [ ] Podが起動するまで待つ
- [ ] Ingress更新を確認する

### 実施後
- [ ] サービスが正常稼働している
- [ ] ヘルスチェックが成功する
- [ ] ユーザーがアクセスできる
- [ ] エラーログに異常がない
- [ ] バックグラウンドジョブが動作している
- [ ] モニタリングで異常がない

### 事後対応
- [ ] ユーザーへの告知を実施
- [ ] 問題をドキュメント化
- [ ] チーム内で振り返りを実施
- [ ] 再移行計画を策定

## 緊急連絡先

ロールバック中に問題が発生した場合の連絡先：

- インフラ担当: ________________
- アプリケーション担当: ________________
- データベース担当: ________________
- 緊急連絡: ________________

## まとめ

- ロールバックは迅速に判断し、実行する
- 状況に応じて適切なレベルを選択する
- Level 1（Ingress切り戻し）が最速で安全
- Level 3（DB復元）は最終手段
- ロールバック後は必ず原因分析を実施する

---

**注意**: ロールバック手順は定期的に見直し、実際の環境変更に合わせて更新してください。
