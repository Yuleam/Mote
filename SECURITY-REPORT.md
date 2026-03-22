# Purl 보안 점검 보고서

작성일: 2026-03-22
범위: 서버(Node.js/Express) + iOS 앱(Flutter) + 인증 시스템 전체

---

## 요약

현재 구현은 기본적인 인증(JWT + bcrypt)과 SQL injection 방어(파라미터 바인딩)를 갖추고 있으나, **App Store 출시 수준의 보안으로는 부족**하다. 아래에 위험도별로 분류한다.

---

## 1. 치명적 (즉시 수정 필요)

### 1-1. JWT Secret 하드코딩 폴백

- **현재 상태**: `server/middleware/auth.js:6` — `JWT_SECRET = process.env.JWT_SECRET || 'knitting-dev-secret-change-in-prod'`
- **위험**: 환경변수 미설정 시 누구나 유효한 JWT를 생성할 수 있음. 실제 프로덕션에서 환경변수가 설정되어 있더라도, 폴백 자체가 사고 위험
- **권장 조치**: 폴백 제거. 환경변수 없으면 서버 시작 거부
- **근거**: [OWASP M1: Improper Credential Usage](https://owasp.org/www-project-mobile-top-10/2023-risks/) — 하드코딩된 자격증명은 1순위 취약점

### 1-2. Rate Limiting 없음 (브루트포스 방어)

- **현재 상태**: `/api/auth/login`, `/api/auth/register`에 요청 횟수 제한 없음
- **위험**: 자동화된 비밀번호 추측 공격에 완전히 노출. 6자 비밀번호 정책과 결합하면 위험이 극대화됨
- **권장 조치**: `express-rate-limit` 도입 — 로그인: IP당 5회/15분, 가입: IP당 3회/시간
- **근거**: [OWASP M3: Insecure Authentication](https://owasp.org/www-project-mobile-top-10/2023-risks/)

### 1-3. 보안 헤더 없음

- **현재 상태**: Strict-Transport-Security, X-Content-Type-Options, X-Frame-Options 등 미설정
- **위험**: MITM, 클릭재킹, MIME 스니핑 공격 가능
- **권장 조치**: `helmet` 미들웨어 추가 (1줄로 해결)
- **근거**: OWASP 권장 HTTP 보안 헤더

---

## 2. 중요 (출시 전 수정 권장)

### 2-1. 입력 길이 제한 없음

- **현재 상태**: `express.json()`에 body size limit 미설정 (기본 100KB이지만 명시적이지 않음). 개별 필드(text, thought, source 등)에 길이 제한 없음
- **위험**: 메모리 소모 DoS, DB 비대화
- **권장 조치**: `express.json({ limit: '100kb' })` 명시 + 주요 필드 길이 검증 (text: 10,000자, thought: 5,000자 등)
- **근거**: [OWASP M4: Insufficient Input/Output Validation](https://owasp.org/www-project-mobile-top-10/2023-risks/)

### 2-2. JWT 30일 고정 만료 + Refresh Token 없음

- **현재 상태**: access token 30일 만료, refresh 메커니즘 없음
- **위험**: 토큰 탈취 시 30일간 무제한 접근. 비밀번호 변경 후에도 기존 토큰 유효
- **권장 조치**: access token 15~30분 + refresh token 14일 + rotation
- **구현 복잡도**: 높음 (서버 + Flutter 모두 변경 필요)
- **현실적 대안**: 출시 시점에서는 만료를 7일로 단축하고, refresh token은 v1.1에서 구현
- **근거**: [JWT Security Best Practices](https://jwt.app/blog/jwt-best-practices/) — access token은 15~30분, refresh token은 7~14일 권장

### 2-3. 이메일 검증 미흡

- **현재 상태**: `email.includes('@')` 한 줄 검증
- **위험**: `@@@`, `test@` 같은 무효 이메일로 가입 가능
- **권장 조치**: 정규식 기반 이메일 형식 검증 + 이메일 인증 코드 발송 (Task 1-1에서 구현 예정)
- **근거**: [OWASP M3: Insecure Authentication](https://owasp.org/www-project-mobile-top-10/2023-risks/)

### 2-4. 에러 메시지 표준화 부족

- **현재 상태**: 일부 에러에서 `err.message` 직접 노출 가능성 (catch 블록에서 console.error 후 generic error 반환은 잘 하고 있으나 일관성 없음)
- **위험**: 스택 트레이스나 내부 정보 노출 가능성
- **권장 조치**: 모든 500 에러를 동일한 형식(`{ error: 'Server error' }`)으로 통일. NODE_ENV=production에서 console.error 세부 억제

### 2-5. 비밀번호 정책 약함

- **현재 상태**: 최소 6자, 복잡도 요구사항 없음
- **위험**: 약한 비밀번호 허용 (예: `123456`, `aaaaaa`)
- **권장 조치**: 최소 8자 + 영문+숫자 조합 권장 (강제하면 UX 저하 → 경고로 처리)

---

## 3. 권장 (출시 후 개선)

### 3-1. 로그아웃 시 토큰 무효화 없음

- **현재 상태**: 클라이언트에서 SharedPreferences 삭제만 수행. 서버에서 토큰 블랙리스트 없음
- **위험**: 탈취된 토큰은 만료까지 유효
- **현실적 대안**: access token 수명 단축(7일→15분)이 선행되면 리스크 감소. 본격적인 블랙리스트는 refresh token 도입 시 함께 구현
- **근거**: [Auth0 Token Best Practices](https://auth0.com/docs/secure/tokens/token-best-practices)

### 3-2. CSRF 보호

- **현재 상태**: 없음
- **위험**: 모바일 앱(Flutter)은 쿠키를 사용하지 않으므로 CSRF 위험 낮음. 웹 UI(capture.html)는 Authorization 헤더 사용 → CSRF 위험 낮음
- **결론**: 현재 아키텍처에서는 낮은 우선순위. 쿠키 기반 인증 도입 시 재평가

### 3-3. Flutter 토큰 저장소

- **현재 상태**: SharedPreferences (평문 저장)
- **권장**: iOS Keychain(`flutter_secure_storage` 패키지) 사용
- **근거**: [Apple 보안 가이드라인](https://developer.apple.com/app-store/review/guidelines/) — Keychain 사용 권장
- **구현 복잡도**: 낮음 (패키지 교체 + 2~3줄 변경)

### 3-4. 비밀번호 재설정 기능 없음

- **현재 상태**: 비밀번호 분실 시 복구 불가
- **권장**: 이메일 인증 구현(Task 1-1) 후 비밀번호 재설정 플로우 추가
- **우선순위**: 이메일 인증 완료 후

### 3-5. Sign in with Apple 미구현

- **현재 상태**: 이메일+비밀번호 인증만 존재
- **Apple 요구사항**: 3rd-party 소셜 로그인을 제공하면 Sign in with Apple도 필수. **현재 소셜 로그인이 없으므로 필수는 아님**
- **권장**: v1.1 이후 검토
- **근거**: [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) 4.8

---

## 우선순위 정리 (구현 순서)

| 순서 | 항목 | 위험도 | 난이도 |
|------|------|--------|--------|
| 1 | JWT Secret 폴백 제거 | 치명적 | 매우 낮음 |
| 2 | helmet 보안 헤더 추가 | 치명적 | 매우 낮음 |
| 3 | express-rate-limit 추가 | 치명적 | 낮음 |
| 4 | 입력 길이 제한 명시 | 중요 | 낮음 |
| 5 | 이메일 형식 검증 강화 | 중요 | 낮음 |
| 6 | 비밀번호 정책 강화 (8자+) | 중요 | 낮음 |
| 7 | JWT 만료 7일로 단축 | 중요 | 낮음 |
| 8 | flutter_secure_storage 교체 | 권장 | 낮음 |
| 9 | Refresh token 구현 | 중요 | 높음 |
| 10 | 비밀번호 재설정 | 권장 | 중간 |

---

## 현재 잘 되어 있는 것

- bcryptjs salt round 10 (적절)
- SQL injection 방어 (파라미터 바인딩 일관 사용)
- CORS 화이트리스트 기반 (적절)
- HTTPS (Railway 자동 제공)
- 로그인 실패 메시지 통일 ("Incorrect email or password" — 이메일 존재 여부 미노출)
- user_id 기반 데이터 격리 (authMiddleware + 쿼리에서 user_id 조건)
- 에러 핸들링에서 내부 정보 미노출 (대부분의 catch 블록)

---

## 참고 자료

- [OWASP Mobile Top 10 2024](https://owasp.org/www-project-mobile-top-10/2023-risks/)
- [JWT Security Best Practices 2025](https://jwt.app/blog/jwt-best-practices/)
- [Auth0: Refresh Tokens](https://auth0.com/blog/refresh-tokens-what-are-they-and-when-to-use-them/)
- [Auth0: Token Best Practices](https://auth0.com/docs/secure/tokens/token-best-practices/)
- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [OWASP Mobile Top 10 Security Guide](https://www.getastra.com/blog/mobile/owasp-mobile-top-10-2024-a-security-guide/)
