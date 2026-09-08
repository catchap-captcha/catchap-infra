# catchap-infra

CatChap 의 **쿠버네티스 매니페스트와 인프라 문서**입니다. 서비스 코드는 들어 있지 않습니다.

```
k8s/     쿠버네티스 매니페스트 28개 — 이것이 새 환경의 정의입니다
문서/     인프라 작업 기록·설계·팀 공유 문서 45개
```

---

## k8s/ — 무엇이 어디에

```
k8s/backend/       백엔드 API        configmap · deployment · service · secret 예시
k8s/frontend/      화면
k8s/captcha/       캡차              namespace · ingress 포함
k8s/behavior-ai/   행동 판별 AI
k8s/50-ingress-공통.yaml         인그레스
k8s/60-pdb-공통.yaml             PodDisruptionBudget
k8s/70-storageclass-wait.yaml    스토리지클래스
k8s/71-kube-prometheus-stack-values.yaml   모니터링(그라파나·경보) 설정
k8s/73-그라파나-대시보드-catchap.yaml       대시보드 14패널
k8s/74-경보규칙-catchap.yaml               경보 7종
k8s/90-rbac-catchap-ci.yaml      CI 가 배포할 때 쓰는 권한
```

## ★비밀값은 여기에 넣지 않습니다

```
20-secret.예시.yaml   ★값 자리에 "여기에-넣지-말-것" 만 있습니다
실제 값               ★카카오클라우드 Secrets Manager
```

⚠️**`.env`·키 파일·비밀번호를 커밋하지 마세요.** 실수로 올렸다면 **지운다고 이력에서 사라지지 않습니다** — 즉시 알리고 **키를 바꿔야** 합니다.

★이 저장소는 만들 때 **비밀값 전수 검사**를 하고 올렸습니다. 나온 긴 문자열은 전부
**SSH 공개키 지문 · 인증서 지문 · DNS TXT 레코드 · 문서 URL** 이었습니다.

## 캡처 이미지는 안 들어갑니다

문서에서 참조하는 콘솔 캡처 **669장(259MB)** 은 git 에 넣지 않았습니다.
저장소가 무거워지고 diff 로 볼 수도 없기 때문입니다. 원본은 작업 PC 의
`인프라-캡처/` 에 있습니다.

---

## 작업 방법

`main` 에 직접 push 하지 않습니다. 브랜치를 따서 PR 로 올립니다.

```bash
git switch -c chore/<요약>
git commit -m "chore(k8s): 무엇을 왜 바꿨나"
git push -u origin HEAD
gh pr create --fill && gh pr merge --auto --squash
```

자세한 것은 `문서/91-팀공유/06-작업방법-커밋-푸시-PR.md` 를 보세요.

## 어디부터 읽으면 되나

```
문서/00-지금하는일.md          지금 무엇을 하고 있나
문서/00-아키텍처-설계.md        전체 그림
문서/00-정리노트.md             서버·네트워크·계정 실측값
문서/91-팀공유/                 팀원께 드리는 설명
문서/93-참고자료/               카카오클라우드 문서에서 배운 것
```

---

## 전체 지도 — CatChap 저장소

이 프로젝트는 저장소 여러 개로 나뉘어 있습니다. **찾는 것이 여기 없으면 아래를 보십시오.**

| 저장소 | 무엇 |
|---|---|
| [`catchap-backend`](https://github.com/catchap-captcha/catchap-backend) | 백엔드 API · DB 마이그레이션(alembic) |
| [`catchap-frontend`](https://github.com/catchap-captcha/catchap-frontend) | 학생·강사·운영자 화면 |
| [`catchap-captcha`](https://github.com/catchap-captcha/catchap-captcha) | 캡차 서비스 · ★Release 에 이미지 자산 2.05GB + 문제은행 |
| [`catchap-behavior-ai`](https://github.com/catchap-captcha/catchap-behavior-ai) | 행동 기반 봇 판별 |
| [`catchap-stt-worker`](https://github.com/catchap-captcha/catchap-stt-worker) | 강의 음성 → 자막 |
| [`catchap-infra`](https://github.com/catchap-captcha/catchap-infra) | ★쿠버네티스 매니페스트 · Argo CD 설정 |
| [`catchap-legacy`](https://github.com/catchap-captcha/catchap-legacy) | 옛 브랜치 35개 (커밋 이력 보존용) |
| ★[`catchap-archive`](https://github.com/catchap-captcha/catchap-archive) | **비공개** — 인프라 문서·캡처·DB 덤프 전부 |

### ★`catchap-archive` 부터 여십시오 (팀 구성원만)

클라우드를 반납해서 **서버는 더 이상 없습니다.** 어떻게 만들었고 왜 그렇게 했는지는
전부 그 저장소에 있습니다. 개인정보가 들어 있어 비공개입니다.

```
인프라-캡처/95-최종상태/          서비스 12종 실측 정본 + 복원 순서
인프라-캡처/95-최종상태/06-배포가-어떻게-돌아갔나.md    배포 7단계 전체
DB-복원/                          표 130개 · 칼럼 1,547개 + 복원 절차
Releases                          DB 덤프 · 옛 서버 백업
```
