# 작업 내용 — 2026-03-22

회원가입 보완 + 보안 점검

---

## 1. 보안 점검 및 수정

### 보고서
- `SECURITY-REPORT.md` 작성 — 치명적 3개, 중요 5개, 권장 5개 항목 분류
- OWASP Mobile Top 10 2024, JWT 모범 사례, Apple App Store 가이드라인 기반

### 치명적 수정 (즉시 적용)

| 항목 | 수정 내용 | 파일 |
|------|-----------|------|
| JWT Secret 하드코딩 폴백 | 폴백 제거, 환경변수 없으면 서버 시작 거부 | `server/middleware/auth.js` |
| 보안 헤더 없음 | `helmet` 미들웨어 추가 | `server/index.js` |
| Rate limiting 없음 | `express-rate-limit` — login/register/resend에 IP당 10회/15분 | `server/index.js` |
| 입력 길이 미제한 | `express.json({ limit: '100kb' })`, 비밀번호 최대 128자 | `server/index.js`, `server/routes/auth.js` |
| 이메일 검증 미흡 | 정규식 `/^[^\s@]+@[^\s@]+\.[^\s@]+$/` + 254자 제한 | `server/routes/auth.js` |
| 비밀번호 정책 약함 | 최소 6자 → 8자로 상향 | `server/routes/auth.js` |
| JWT 만료 너무 김 | 30일 → 7일로 단축 | `server/routes/auth.js` |

### 추가된 의존성
- `helmet` — HTTP 보안 헤더
- `express-rate-limit` — 요청 빈도 제한
- `nodemailer` — 이메일 발송

---

## 2. 이메일 인증 기능

### 서버

**새 파일**: `server/services/email.js`
- Nodemailer + Gmail SMTP (환경변수: `SMTP_USER`, `SMTP_PASS`)
- SMTP 미설정 시 콘솔 로그 출력 (개발 편의)
- HTML 이메일 템플릿 (Purl 스타일)

**DB 변경** (`server/db.js`):
- `users` 테이블에 `verified` 컬럼 추가 (기존 사용자는 자동으로 `verified = 1`)
- `email_verification_codes` 테이블 신규 생성

**API 변경** (`server/routes/auth.js`):

| 엔드포인트 | 변경 내용 |
|------------|-----------|
| `POST /api/auth/register` | 가입 시 `verified = 0`으로 생성, 6자리 인증 코드 이메일 발송. 미인증 계정 재가입 시 비밀번호 업데이트 + 새 코드 발송 |
| `POST /api/auth/verify` (신규) | 이메일 + 코드 검증 → 성공 시 `verified = 1` + JWT 토큰 반환 |
| `POST /api/auth/resend` (신규) | 인증 코드 재발송 (기존 코드 무효화) |
| `POST /api/auth/login` | 미인증 계정 로그인 시 403 + `needsVerification: true` 반환 |

### Flutter (`flutter/lib/screens/auth_screen.dart`)
- 가입 성공 → 인증 코드 입력 화면으로 전환
- 6자리 숫자 코드 입력 (큰 글씨, 가운데 정렬)
- "코드 다시 보내기" / "돌아가기" 버튼
- 로그인 시 미인증 계정이면 자동으로 인증 화면 표시

---

## 3. 비밀번호 확인 필드

**파일**: `flutter/lib/screens/auth_screen.dart`

- 가입 탭에서만 "비밀번호 확인" 필드 표시
- 실시간 일치 여부 검증 — 불일치 시 빨간 안내 텍스트
- 비밀번호 불일치 또는 8자 미만이면 가입 버튼 비활성

---

## 4. 사용자 프로필 질문

### 서버

**DB 변경** (`server/db.js`):
- `user_profiles` 테이블 신규 생성 (`user_id`, `occupation`, `context`, `created_at`)

**API** (`server/routes/auth.js`):

| 엔드포인트 | 설명 |
|------------|------|
| `GET /api/auth/profile` | 프로필 조회 (인증 필요) |
| `POST /api/auth/profile` | 프로필 저장/업데이트 (인증 필요) |

### Flutter (`flutter/lib/screens/onboarding_screen.dart`)
- 기존 1페이지 → 2페이지 플로우로 변경
  - 페이지 1: 환영 + 탭 안내 (기존과 동일)
  - 페이지 2: 프로필 질문
    - "어떤 일을 하고 계세요?" (자유 입력)
    - "주로 어떤 순간에 영감을 잡으시나요?" (자유 입력)
- "건너뛰기" 버튼으로 무응답 가능
- 다정한 톤: "조금만 알려주세요", "부담 없이, 건너뛰어도 괜찮아요"

### Flutter API (`flutter/lib/services/api_service.dart`)
- `register()` — 반환 타입 `Map<String, dynamic>`으로 변경 (needsVerification 처리)
- `login()` — 반환 타입 `Map<String, dynamic>`으로 변경 (needsVerification 처리)
- `verify()`, `resendCode()`, `getProfile()`, `saveProfile()` 추가

---

## 배포 전 필요사항

### Railway 환경변수

| 변수 | 용도 | 필수 |
|------|------|------|
| `JWT_SECRET` | JWT 서명 키 | 필수 (없으면 서버 시작 안 됨) |
| `SMTP_USER` | Gmail 주소 | 이메일 인증용 |
| `SMTP_PASS` | Gmail 앱 비밀번호 | 이메일 인증용 |

### Gmail 앱 비밀번호 생성 방법
1. Google 계정 → 보안 → 2단계 인증 활성화
2. 앱 비밀번호 생성 (앱: "메일", 기기: "기타" → "Purl")
3. 생성된 16자리 비밀번호를 `SMTP_PASS`에 설정

### 변경된 파일 목록

```
server/
  index.js              — helmet, rate-limit, body limit 추가
  middleware/auth.js     — JWT_SECRET 폴백 제거
  routes/auth.js         — 전체 재작성 (이메일 인증 + 프로필 API)
  db.js                  — verified 컬럼, email_verification_codes, user_profiles 테이블
  services/email.js      — 신규 (Nodemailer 이메일 발송)
  package.json           — helmet, express-rate-limit, nodemailer 추가

flutter/lib/
  screens/auth_screen.dart       — 비밀번호 확인 + 인증 코드 화면
  screens/onboarding_screen.dart — 프로필 질문 페이지 추가
  services/api_service.dart      — register/login 반환 타입 변경, verify/resend/profile API 추가

SECURITY-REPORT.md     — 보안 점검 보고서
```

---

## 남은 과제 (보안 보고서 기준)

| 항목 | 위험도 | 상태 |
|------|--------|------|
| flutter_secure_storage 교체 | 권장 | 미구현 |
| Refresh token 구현 | 중요 | 미구현 (v1.1 권장) |
| 비밀번호 재설정 | 권장 | 미구현 (이메일 인증 완료 후 추가) |
| 로그아웃 토큰 무효화 | 권장 | 미구현 (refresh token과 함께) |
| Sign in with Apple | 권장 | 불필요 (소셜 로그인 없으므로) |
