# DB 표 구조 — 클라우드 반납 대비 (2026-08-12 실측)

## 무엇인가

관리형 MySQL 에서 **살아 있는 표 구조를 그대로** 받아 둔 것입니다.
★데이터는 한 줄도 들어 있지 않습니다.

| 파일 | DB | 담긴 것 |
|---|---|---|
| `catchap_ai-표구조.sql` | `catchap_ai` | 표 9개 |
| `catchap-표구조.sql` | `catchap` | 표 99개 + 뷰 1개 · alembic `merge_heads_0807` |

`catchap_captcha` 는 여기 없습니다. **문제은행 데이터까지 같이 있어야 의미가 있어서**
`catchap-captcha` 저장소의 Release `assets-20260812` 에 이미지 자산과 함께 두었습니다.

## 왜 필요한가

★**카카오클라우드 자원은 전부 반납 대상**입니다. 관리형 MySQL 이 사라지면
표 구조를 되살릴 방법이 필요합니다.

```
catchap       alembic 이 만든다 → ★그래도 남겨 둔다.
              자동 생성과 실제가 어긋났는지 나중에 대조할 수 있어야 한다.

catchap_ai    ★alembic 밖이다 → 마이그레이션이 자동으로 안 돈다.
              ★이 파일이 없으면 표를 만들 방법이 없다.
```

## 되살리는 법

```bash
# 1. 새 DB 를 만든다
CREATE DATABASE catchap CHARACTER SET utf8mb4;
CREATE DATABASE catchap_ai CHARACTER SET utf8mb4;

# 2-a. catchap 은 alembic 이 정석이다
alembic upgrade head          # merge_heads_0807 까지 간다

# 2-b. catchap_ai 는 이 파일로만 만들 수 있다
mysql -h <새DB> -u <계정> -p catchap_ai < catchap_ai-표구조.sql

# 3. 뷰를 다시 만든다 (덤프에서 빠져 있음 — 아래 참고)
mysql ... < catchap-behavior-ai/migrations/catchap_ai_view_training_dataset.sql
```

⚠️**뷰 `ai_training_dataset` 은 빠져 있습니다.** 앱 계정에 `SHOW VIEW` 권한이 없어
뜨지 못했습니다. 정의는 `catchap-behavior-ai` 저장소 `migrations/` 에 있습니다.

## 어떻게 뽑았나

```
자격증명이 ★컨테이너 환경변수에 없다 — 금고 로더가 파이썬 프로세스 안에 넣는다.
→ 밖으로 꺼내지 않으려고 mysqldump 대신 ★파드 안에서 파이썬으로 만들고
  파일만 꺼냈다. 화면·디스크 어디에도 값이 안 남았다.
```

## 같은 파일이 서비스 저장소에도 있습니다

```
catchap-behavior-ai/db/실측-표구조-20260812.sql
catchap-backend/alembic/실측-표구조-20260812.sql
```

⚠️★**그쪽에 먼저 넣은 것은 판단 착오였습니다.** 서비스 저장소는 main 에 무엇이
들어가든 이미지를 다시 굽고 배포합니다. 실제로 재배포가 돌았습니다(결과는 정상).
**복원용 자료는 여기(인프라)가 맞는 자리입니다.**
