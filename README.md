# catchap-infra

CatChap 의 **쿠버네티스 매니페스트와 인프라 문서**입니다. 서비스 코드는 들어 있지 않습니다.

```
k8s/     쿠버네티스 매니페스트 yaml 42개 (2026-09-08 기준) — 이것이 새 환경의 정의입니다
         ★Argo CD 가 자동으로 맞추는 것은 앱 폴더 5개뿐이고, 나머지(인그레스 공통·HPA·PDB·감시·GPU·ingress-nginx)는 사람이 apply 합니다
```

인프라 작업 기록·설계·팀 공유 문서는 이 저장소에 없습니다 — 비공개 저장소 `catchap-archive` 에 있습니다(맨 아래 「전체 지도」).

---

## k8s/ — 무엇이 어디에

```
k8s/backend/       백엔드 API        configmap · deployment · service · migrate Job(PreSync alembic)
k8s/frontend/      화면
k8s/captcha/       캡차              namespace · ingress · 스키마 검사 Job 포함
k8s/behavior-ai/   행동 판별 AI
k8s/stt-worker/    음성 → 자막 (GPU · 1벌)
k8s/argocd/        Argo CD Application 5개 (위 폴더 5개를 각각 봄)
k8s/ingress-nginx/ 컨트롤러 본체 · 진짜 IP 설정 · 보안 헤더   ★사람이 apply
k8s/50-ingress-공통.yaml         www · api 인그레스 3개 + 요청 제한        ★사람이 apply
k8s/60-pdb-공통.yaml             PodDisruptionBudget 5개                  ★사람이 apply
k8s/61-hpa-공통.yaml             HPA 4개 (2~4벌)                          ★사람이 apply
k8s/70-storageclass-wait.yaml    스토리지클래스 (감시 스택 PVC 가 씀)      ★사람이 apply
k8s/71-kube-prometheus-stack-values.yaml   모니터링(그라파나·경보) helm 값  ★helm 으로 사람이
k8s/73-그라파나-대시보드-catchap.yaml       대시보드
k8s/74-경보규칙-catchap.yaml               경보 7종
k8s/75-networkpolicy-공통.yaml   네임스페이스 통신 규칙                    ★사람이 apply
k8s/80-nvidia-device-plugin.yaml · 81-dcgm-exporter.yaml   GPU            ★사람이 apply
k8s/90-rbac-catchap-ci.yaml      운영 VM 의 kubectl 권한                  ★사람이 apply
k8s/예시-시크릿/                 부트스트랩 K8s 시크릿 만드는 명령(주석) — 값 없음
```

## ★비밀값은 여기에 넣지 않습니다

```
예시-시크릿/*.yaml.예시   ★값 자리에 "여기에-넣지-말-것" 만 있습니다 (backend · captcha · behavior-ai · stt-worker)
실제 값                   ★카카오클라우드 Secrets Manager (앱이 기동할 때 읽음)
무엇을 만들어야 하나      catchap-archive: 01-인프라-기록/95-최종상태/02-Secrets-KMS/02-비밀값-전체목록-다시-만들-때.md
```

⚠️**`.env`·키 파일·비밀번호를 커밋하지 마세요.** 실수로 올렸다면 **지운다고 이력에서 사라지지 않습니다** — 즉시 알리고 **키를 바꿔야** 합니다.

★이 저장소는 만들 때 **비밀값 전수 검사**를 하고 올렸습니다. 나온 긴 문자열은 전부
**SSH 공개키 지문 · 인증서 지문 · DNS TXT 레코드 · 문서 URL** 이었습니다.

## 캡처 이미지는 안 들어갑니다

콘솔 캡처는 git 에 넣지 않았습니다. 저장소가 무거워지고 diff 로 볼 수도 없기 때문입니다.
캡처 1,301장과 문서 전부는 비공개 저장소 `catchap-archive` 의 `01-인프라-기록/` 에 있습니다.

---

## 작업 방법

`main` 에 직접 push 하지 않습니다. 브랜치를 따서 PR 로 올립니다.

```bash
git switch -c chore/<요약>
git commit -m "chore(k8s): 무엇을 왜 바꿨나"
git push -u origin HEAD
gh pr create --fill && gh pr merge --auto --squash
```

자세한 것은 `catchap-archive` 의 `01-인프라-기록/91-팀공유/06-작업방법-커밋-푸시-PR.md` 를 보세요.

## 어디부터 읽으면 되나 (전부 `catchap-archive` 안)

```
00-10년-뒤에-읽는-사람에게.md                          무엇이었고 · 어떻게 진행됐고 · 마지막에 어떻게 생겼고 · 다시 세우려면
01-인프라-기록/00-아키텍처-그림.md                      전체 그림
01-인프라-기록/95-최종상태/                             서비스별 실측 정본 · 처음부터 다시 만드는 순서(03) · 배포 7단계(06)
01-인프라-기록/91-팀공유/                               팀원께 드리는 설명
01-인프라-기록/93-참고자료/                             카카오클라우드 문서에서 배운 것
```

---

## 전체 지도 — CatChap 저장소

이 프로젝트는 저장소 여러 개로 나뉘어 있습니다. **찾는 것이 여기 없으면 아래를 보십시오.**

| 저장소 | 무엇 |
|---|---|
| [`catchap-backend`](https://github.com/catchap-captcha/catchap-backend) | 백엔드 API · DB 마이그레이션(alembic) |
| [`catchap-frontend`](https://github.com/catchap-captcha/catchap-frontend) | 학생·강사·운영자 화면 |
| [`catchap-captcha`](https://github.com/catchap-captcha/catchap-captcha) | 캡차 서비스 · ★Release 에 이미지 자산 약 2.0GiB + 문제은행 핵심 8표(0812) |
| [`catchap-behavior-ai`](https://github.com/catchap-captcha/catchap-behavior-ai) | 행동 기반 봇 판별 |
| [`catchap-stt-worker`](https://github.com/catchap-captcha/catchap-stt-worker) | 강의 음성 → 자막 |
| [`catchap-infra`](https://github.com/catchap-captcha/catchap-infra) | ★쿠버네티스 매니페스트 · Argo CD 설정 |
| [`catchap-legacy`](https://github.com/catchap-captcha/catchap-legacy) | 옛 브랜치 35개 (커밋 이력 보존용) |
| ★[`catchap-archive`](https://github.com/catchap-captcha/catchap-archive) | **비공개** — 인프라 문서·캡처·DB 덤프 전부 |

### ★`catchap-archive` 부터 여십시오 (팀 구성원만)

2026-09-08 에 마지막 기록을 남기고 카카오클라우드 자원은 그 주에 삭제하기로 했습니다 — **서버는 더 이상 없습니다.**
어떻게 만들었고 왜 그렇게 했는지는 전부 그 저장소에 있습니다. 개인정보가 들어 있어 비공개입니다.

```
00-10년-뒤에-읽는-사람에게.md                    입구 — 이것부터
01-인프라-기록/95-최종상태/                       서비스 12종 실측 정본 + 처음부터 다시 만드는 순서(03)
01-인프라-기록/95-최종상태/06-배포가-어떻게-돌아갔나.md    배포 7단계 전체
01-인프라-기록/95-최종상태/02-Secrets-KMS/02-비밀값-전체목록-다시-만들-때.md   되살릴 때 새로 만들 비밀값 전부 (값 없음)
02-DB-복원/                                      표 130개 · 칼럼 1,548개 + 복원 절차
Releases                                         DB 덤프 · 옛 서버 백업
```
