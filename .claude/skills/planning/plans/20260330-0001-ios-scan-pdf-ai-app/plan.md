# iOS Scan PDF AI App — Product Plan

**Ngày:** 2026-03-30
**Version:** 1.0
**Target:** iOS 17+ | iPhone + iPad
**Team:** 1–2 iOS developers + 1 designer
**Launch:** 4 tháng (App Store)

---

## Executive Summary

Ứng dụng biến iPhone thành máy quét thông minh: chụp tài liệu → AI xử lý → tương tác bằng chat. Điểm khác biệt killer: **AI chat trực tiếp với tài liệu quét** — thay vì chỉ lưu trữ như Adobe Scan, người dùng hỏi AI để trích xuất thông tin, tóm tắt, dịch ngay trên tài liệu đang mở. MVP tập trung Groups 1–4 (Scan → AI Processing → Annotate → AI Chat). Phase 2 bổ sung Library + Security. Phase 3 mở rộng Collaboration + Integrations + Advanced AI.

---

## 3-Phase Roadmap

| Phase | Thời gian | Mục tiêu | Groups |
|-------|-----------|----------|--------|
| **Phase 1 — MVP** | 0–3 tháng | Scan + AI chat hoạt động trên App Store | 1, 2, 3, 4 |
| **Phase 2 — Growth** | 3–6 tháng | Library + Security + Team Collaboration | 5, 6, 7, 8 |
| **Phase 3 — Scale** | 6–12 tháng | Integrations + Advanced AI + Monetization | 9, 10, 11, 12 |

---

## Feature Table (12 Groups)

| # | Group | Priority | Phase | Effort | iOS Framework / SDK |
|---|-------|----------|-------|--------|---------------------|
| 1 | Scan & Import | 🔴 High | P1 | 3w | AVFoundation, VisionKit, PDFKit |
| 2 | AI Document Processing | 🔴 High | P1 | 2w | Vision, Core ML, Claude API |
| 3 | Edit & Annotate | 🔴 High | P1 | 2w | PDFKit, PencilKit, PencilKit overlay |
| 4 | AI Chat with Document | 🔴 High | P1 | 3w | SwiftUI, Claude API, Swift Data |
| 5 | Library Management | 🟡 Medium | P2 | 2w | Swift Data, CoreSpotlight |
| 6 | Export & Share | 🟡 Medium | P2 | 1w | PDFKit, UIActivityViewController |
| 7 | Security | 🟡 Medium | P2 | 2w | LocalAuthentication, CryptoKit |
| 8 | Team Collaboration | 🟡 Medium | P2 | 4w | CloudKit, Swift Concurrency |
| 9 | Integrations | 🟢 Low | P3 | 3w | FileProvider, App Intents |
| 10 | Smart UX | 🟢 Low | P3 | 2w | WidgetKit, App Intents, CoreHaptics |
| 11 | Monetization | 🟢 Low | P3 | 2w | StoreKit 2 |
| 12 | Advanced AI | 🟢 Low | P3 | 3w | Claude API, Vision |

---

## Top 3 Risks & Mitigation

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **App Store Review delay** — camera + Face ID permissions bị reject | HIGH | Sử dụng usage descriptions cực kỳ rõ ràng, test kỹ permission flow trước submit |
| 2 | **Claude API latency** — AI chat chậm >3s kill UX | HIGH | Stream responses, local caching cho documents đã parse, optimistic UI |
| 3 | **OCR accuracy** — Vietnamese handwriting thất bại | MEDIUM | Fallback cloud OCR (Claude Vision), let user correct & retrain model |

---

## Success Metrics (KPIs)

| Phase | Metric | Target |
|-------|--------|--------|
| P1 | DAU sau 1 tháng launch | 5,000 |
| P1 | Average scan → chat completion | < 90s |
| P1 | App Store rating | ≥ 4.5★ |
| P2 | Library adoption rate | > 60% users |
| P2 | Monthly active collaborators | > 500 teams |
| P3 | MRR từ subscriptions | > $5,000 |
| P3 | Advanced AI feature usage | > 30% MAU |

---

## Killer Differentiator

**"Scan → Ask → Done"** — AI Chat inline trong document viewer. Adobe Scan chỉ quét & lưu. Người dùng mở tài liệu → nhìn thấy chat panel ngay bên dưới → hỏi "Trích xuất tất cả số điện thoại" hoặc "Dịch trang 2 sang tiếng Anh" → copy kết quả. Không cần export, không cần app khác.

---

## Detailed Phase Plans

- [Phase 1 — MVP (Groups 1–4)](./phase-01-mvp.md)
- [Phase 2 — Growth (Groups 5–8)](./phase-02-growth.md)
- [Phase 3 — Scale (Groups 9–12)](./phase-03-scale.md)