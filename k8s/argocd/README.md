# ArgoCD — main 에 병합되면 저절로 배포되게

```
main 에 병합  →  CI 가 이미지를 만들고 매니페스트의 태그를 고침
              →  ★ArgoCD 가 이 저장소를 지켜보다가 클러스터에 반영
```

## ★지금은 자동 동기화가 꺼져 있습니다

`syncPolicy.automated` 를 주석으로 막아 뒀습니다. **화면에서 Sync 를 눌러야** 반영됩니다.
무엇이 어떻게 바뀌는지 눈으로 본 뒤에 켭니다.

## ⚠️`prune` 은 반드시 나중에

```
prune: true   →  ★git 에 없는 것을 클러스터에서 지웁니다
                 손으로 만든 Secret 4개가 날아갑니다
                 backend-secret · captcha-secret · behavior-ai-secret · catchap-registry
```

★**켜기 전에 그 4개를 git 로 옮기든(SealedSecrets 등) 예외로 두든 정해야 합니다.**

## 설치

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.0/manifests/install.yaml
kubectl apply -f k8s/argocd/
```

★**판본을 못 박습니다**(`v3.5.0`). `stable` 은 어느 날 조용히 바뀝니다.

## ⬜비공개 저장소 읽을 자격이 필요합니다

이 저장소는 Private 이라 ArgoCD 가 그냥은 못 읽습니다. **읽기 전용 Deploy key** 를
만들어 넣습니다.

```bash
# 1) 키를 만든다 (비밀키는 출력하지 않는다)
ssh-keygen -t ed25519 -N '' -f argocd-infra -C 'argocd@catchap-infra'

# 2) argocd-infra.pub 를 GitHub 에 등록
#    catchap-infra → Settings → Deploy keys → Add deploy key
#    ★Allow write access 는 체크하지 않습니다 (읽기 전용)

# 3) 비밀키를 클러스터에 넣는다
kubectl create secret generic infra-repo -n argocd \
  --from-literal=type=git \
  --from-literal=url=git@github.com:catchap-captcha/catchap-infra.git \
  --from-file=sshPrivateKey=argocd-infra
kubectl label secret infra-repo -n argocd argocd.argoproj.io/secret-type=repository

# 4) 로컬 비밀키를 지운다
rm -f argocd-infra
```

⚠️이 방법을 쓰면 `app-*.yaml` 의 `repoURL` 을 `git@github.com:...` 형태로 바꿔야 합니다.
토큰(PAT)을 쓰실 거면 `https://` 그대로 두고 `username`/`password` 로 넣습니다.

## 화면 열기

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
# https://localhost:8080  ·  아이디 admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

⚠️**첫 비밀번호는 바꾸고 `argocd-initial-admin-secret` 을 지우세요.**

## 되돌리기

```bash
kubectl delete ns argocd     # ArgoCD 만 사라집니다. catchap 은 그대로입니다
```

★`finalizers` 때문에 Application 을 지우면 **딸린 리소스도 같이 지워집니다.**
앱만 떼고 싶으면 `kubectl patch app <이름> -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge` 를 먼저 합니다.
