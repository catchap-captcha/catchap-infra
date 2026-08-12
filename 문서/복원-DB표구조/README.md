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

## ⚠️2026-08-12 추가 — `catchap_captcha-표구조.sql`

★**적대적 점검에서 구멍을 찾았습니다.**

릴리스 `assets-20260812` 의 `catchap_captcha-data.sql.gz` 는 **INSERT 만** 들어 있고
**CREATE TABLE 이 없습니다.** 그런데 라벨링 표 7개는 **어느 저장소에도 정의가
없었습니다.**

```
label_admin_sessions · label_admin_users · label_events · label_legacy_reviews
label_publish_jobs   · label_revisions   · label_tasks
```

→ 반납 뒤에 되살리면 **「표가 없다」로 실패**합니다. 데이터가 있어도 못 넣습니다.

| 표 | 정의가 어디 있었나 |
|---|---|
| `captcha_*` 14개 | `catchap-captcha/deploy/schema.sql` · `catchap-backend/alembic/` |
| `behavior_*` 2개 | `catchap-captcha/deploy/schema.sql` |
| **`label_*` 7개** | ❌**없음** — 그래서 이 파일을 만들었습니다 |

### 이 파일

```
표 21개 · 22,812바이트 · ★INSERT 0건 (구조만)
뽑은 법  파드 안에서 SHOW CREATE TABLE
        → 자격증명이 밖으로 나가지 않습니다 (금고 로더가 프로세스 안에만 넣습니다)
확인    password 로 걸린 3줄은 전부 ★칼럼 이름 (`password_hash` · `must_change_password`)
```

### 되살리는 순서

```bash
CREATE DATABASE catchap_captcha CHARACTER SET utf8mb4;
mysql ... catchap_captcha < catchap_captcha-표구조.sql     # ① 표 만들기
gunzip -c catchap_captcha-data.sql.gz | mysql ... catchap_captcha   # ② 데이터
```

★**①을 건너뛰면 ②가 통째로 실패합니다.**

### ⬜아직 정하지 못한 것 — 행동AI 학습 데이터

백업에 **안 들어간 표 13개(125,604행)** 가 있습니다. 대부분 만료되는 것이지만,
**`captcha_behavior_batches` 74,670행은 성원님의 행동AI 학습 데이터**입니다.

```
captcha_behavior_batches        74,670행   ★행동AI 학습 자료
captcha_behavior_sessions        5,721행
captcha_behavior_fingerprints    3,031행
behavior_summaries               3,929행
behavior_shadow_predictions      3,529행
captcha_challenges_v2 · captcha_challenge_objects · captcha_attempts · captcha_tokens
label_admin_users · label_admin_sessions   ← ★비밀번호 해시라 일부러 뺐습니다
```

⚠️**반납하면 사라집니다.** 성원님께 필요한지 여쭙고 결정해야 합니다.
