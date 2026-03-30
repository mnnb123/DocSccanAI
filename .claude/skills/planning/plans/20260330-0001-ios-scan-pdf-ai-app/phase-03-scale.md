# Phase 3 — Scale: Integrations + Advanced AI + Monetization
**Ngày:** 2026-03-30 | **Độ ưu tiên:** 🟢 MEDIUM-LOW

---

## Tổng quan

| Mục | Chi tiết |
|-----|----------|
| **Thời gian** | 6–12 tháng (tuần 25–52) |
| **Mục tiêu** | Mở rộng hệ sinh thái, Advanced AI, doanh thu |
| **Groups** | 9, 10, 11, 12 |
| **Developer weeks** | ~10 weeks tổng (3+2+2+3) |
| **Designer weeks** | ~6 weeks tổng |

---

## Group 9 — Integrations

### 9.1 Mô tả
iCloud Drive, Google Drive, Dropbox sync. iOS Shortcuts automation. REST API cho power users.

### 9.2 User Stories
- *"As a enterprise user, I want Google Drive sync so that scanned documents appear in my Drive folder"*
- *"As a power user, I want a Shortcut 'Scan & Summarize' so that I automate my daily workflow"*
- *"As a developer, I want REST API access so that I can integrate with my company's internal tools"*

### 9.3 MVP Scope
- iCloud Drive sync (FileProvider + DocumentGroup)
- Google Drive import/export (Google Drive API v3)
- Dropbox import/export (Dropbox API v2)
- iOS Shortcuts App Intents (Shortcuts app support)
- REST API (API key auth, Phase 3 backend required)

### 9.4 Tech Stack
- **FileProvider** — iCloud Drive integration
- **GoogleAPIClientForREST/GoogleSignIn** — Google Drive
- **SwiftyDropbox** — Dropbox SDK
- **App Intents** — Shortcuts integration
- **Vapor/Hummingbird** — REST API backend (Go/Node/Python tuỳ team)

### 9.5 Implementation Steps

```
Step 9.1: iCloud Drive sync
  File: iCloudSyncService.swift
  - FileManager ubiquityIdentityToken
  - NSMetadataQuery for .icloud documents
  - UIDocument + NSDocument协同
  - Conflict resolution: newest wins

Step 9.2: Google Drive integration
  File: GoogleDriveService.swift
  - GIDSignIn for OAuth2
  - List files, upload PDF, download PDF
  - Bidirectional sync with local library

Step 9.3: Dropbox integration
  File: DropboxService.swift
  - DropboxClientsManager OAuth2
  - Same operations as Google Drive

Step 9.4: iOS Shortcuts
  File: ScanDocumentIntent.swift (App Intents)
  - Intent: ScanDocument → returns PDFDocument
  - Parameter: folderName (optional)
  - Parameter: autoTag (boolean)
  - Also: SummarizeDocumentIntent, SearchLibraryIntent

Step 9.5: REST API (backend)
  Server: Go/Vapor API server
  Endpoints:
    POST /v1/documents/scan — upload image → return PDF
    POST /v1/documents/chat — chat with document
    GET  /v1/documents — list user's documents
    POST /v1/webhooks — receive external triggers
  Auth: API key in Authorization header
  Rate limit: 100 req/min per API key
```

### 9.6 Effort: 3 weeks

---

## Group 10 — Smart UX

### 10.1 Mô tả
Home screen widget, Spotlight search, Siri shortcuts, haptic feedback.

### 10.2 User Stories
- *"As a busy executive, I want a widget showing my 3 most recent documents so that I can open them without opening the app"*
- *"As a user, I want to say 'Hey Siri, scan a document' so that I can scan hands-free"*
- *"As a power user, I want Spotlight search to find my documents so that I don't need to open the app"*

### 10.3 MVP Scope
- Home screen widget: Recent Documents (WidgetKit)
- Spotlight search integration (Core Spotlight CSSearchableIndex)
- Siri shortcuts via App Intents
- Haptic feedback throughout app
- Animations: page turn, scan capture, chat bubble

### 10.4 Tech Stack
- **WidgetKit** — Widget extension (SwiftUI)
- **Core Spotlight** — CSSearchableIndex
- **App Intents** — Shortcuts + Siri
- **CoreHaptics** — CHHapticEngine for custom patterns
- **SwiftUI animations** — .animation(.spring()) throughout

### 10.5 App Store Considerations
- Widget extension requires App Group shared between main app + widget
- Siri permission: not required (App Intents auto-handles)

### 10.6 Implementation Steps

```
Step 10.1: Widget extension
  File: RecentDocumentsWidget.swift (WidgetKit)
  - Widget type: Static (small: 1 doc, medium: 3 docs, large: 5 docs)
  - Data: App Group UserDefaults shared with main app
  - Tap: deep link to document (doc://open?id=xxx)

Step 10.2: Spotlight indexing
  File: SpotlightIndexer.swift
  - On document save: CSSearchableIndex.default().indexSearchableItems()
  - Attributes: title, full text (OCR), tags, dates
  - Remove from index on document delete

Step 10.3: Siri shortcuts
  File: AppIntents.swift
  - AppShortcutsProvider with AppIntent phrases:
    - "Scan a document" → ScanDocumentIntent
    - "Summarize my last document" → SummarizeLastIntent
  - Parameterized: "Find [query] in [app name]"

Step 10.4: Haptic feedback
  File: HapticManager.swift
  - Impact: light (navigation), medium (scan capture), rigid (error)
  - Notification: success (scan done), warning, error
  - Apply throughout: scan button tap, annotation apply, share action

Step 10.5: Animations
  - Page turn: 3D flip animation in PDF viewer
  - Chat bubble: scale-in + fade
  - Sheet presentation: spring animation
  - Scan capture: flash overlay + haptic
```

### 10.7 Effort: 2 weeks

---

## Group 11 — Monetization

### 11.1 Mô tả
Freemium model: free tier giới hạn, subscription cho AI features.

### 11.2 User Stories
- *"As a occasional user, I want a free tier so that I can scan 5 documents per month without paying"*
- *"As a professional, I want unlimited AI credits so that I can process 50 documents per day"*
- *"As a family, I want a family plan so that 5 of us can share AI quota"*

### 11.3 MVP Scope
- Free tier: 5 scans/month, basic annotation
- Premium: $4.99/month hoặc $39.99/year
  - Unlimited scans
  - Unlimited AI chat (50 req/day), AI summary, AI translation
  - Cloud sync
  - Advanced export
- AI Credit system: pay-per-use cho heavy tasks (flashcard generation, document comparison)
- Family plan: $7.99/month (5 members, shared AI quota)

### 11.4 Tech Stack
- **StoreKit 2** — Subscriptions, In-App Purchase
- **RevenueCat** (recommended) — unified subscriptions across platforms

### 11.5 App Store Review Note
- Subscription pricing must comply with Apple's guidelines
- "Free tier" cannot be misleading — clearly state limits
- Auto-renewable subscriptions require cancellation flow in app

### 11.6 Implementation Steps

```
Step 11.1: StoreKit 2 setup
  File: StoreManager.swift
  - Product IDs: premium_monthly, premium_yearly, ai_credits_10
  - StoreKit.StoreKit1 (backward compat for older devices)
  - await StoreKit.Store().products(for: productIDs)

Step 11.2: Entitlement checking
  File: EntitlementManager.swift
  - Check: Transaction.currentEntitlements
  - Feature gating: isScanUnlimited, isAIEnabled, isCloudSyncEnabled
  - Graceful degradation: show "Upgrade" paywall

Step 11.3: AI credit tracking
  File: CreditManager.swift
  - Track: monthly AI request count per user
  - Tier limits: free=20/month, premium=50/day
  - Pay-per-use: deduct from credit balance
  - Persist: StoreKit Transaction history

Step 11.4: Paywall UI
  File: PaywallView.swift (SwiftUI)
  - Feature comparison table (free vs premium)
  - Monthly/yearly toggle with savings badge
  - Family plan CTA
  - Restore purchases button

Step 11.5: Paywall trigger
  - Trigger on: 6th scan attempt (free tier limit)
  - Trigger on: 21st AI request
  - Show once per session, dismissable
```

### 11.7 Effort: 2 weeks

---

## Group 12 — Advanced AI Features

### 12.1 Mô tả
Compare 2 documents, AI flashcards, cited answers, document templates.

### 12.2 User Stories
- *"As a lawyer, I want to compare contract v1 and v2 side-by-side so that I can spot changes instantly"*
- *"As a student, I want AI flashcards from my lecture notes so that I can study efficiently"*
- *"As a recruiter, I want cited answers so that I can verify AI information against the source"*

### 12.3 MVP Scope
- Document comparison (diff view: highlights added/removed/changed text)
- AI flashcards generation (Claude extracts Q&A pairs from document)
- Cited answers (AI answers with [Page X] citations — enhance from Phase 1)
- Document templates (pre-built: invoice, contract, receipt → smart fill)

### 12.4 Tech Stack
- **Claude API** — diff comparison, flashcard generation
- **Vision** — page-level diff highlighting
- **PDFKit** — overlay annotations for diff visualization

### 12.5 Implementation Steps

```
Step 12.1: Document comparison
  File: DocumentDiffService.swift
  - Load two PDFs → extract text per page
  - Send both texts to Claude with prompt:
    "Compare these two versions. Return: {added: string[], removed: string[], changed: [{old, new}]}"
  - Overlay color-coded annotations on PDF:
    Green = added, Red = removed, Yellow = changed

Step 12.2: Flashcard generation
  File: FlashcardService.swift
  - Send document text to Claude:
    "Generate 5-10 flashcards as JSON: {question, answer, pageRef}"
  - Display as swipeable card UI
  - Spaced repetition: SM-2 algorithm (simple interval tracking)

Step 12.3: Cited answers (enhancement)
  File: CitationEnhancer.swift
  - Phase 1 basic citations → Phase 3 precise citations
  - Parse Claude response for page references
  - Highlight cited text in PDF on tap
  - Link: chat bubble → PDF page scroll to citation

Step 12.4: Document templates
  File: TemplateService.swift
  - Pre-built PDF templates: Invoice, Contract, Receipt, ID Card
  - Smart fill: extract key fields → auto-populate template
  - User creates: fillable PDF form → save as reusable template
```

### 12.6 Effort: 3 weeks

---

## Phase 3 Todo List

- [ ] Group 9: iCloud Drive + Google Drive + Dropbox + Shortcuts + REST API (3w)
- [ ] Group 10: Widget + Spotlight + Siri + Haptics (2w)
- [ ] Group 11: StoreKit 2 + subscriptions + credit system (2w)
- [ ] Group 12: Diff comparison + flashcards + cited answers + templates (3w)
- [ ] App Group setup for widget (capability + entitlements)
- [ ] REST API backend development
- [ ] RevenueCat / StoreKit testing in sandbox
- [ ] Family sharing setup in App Store Connect

---

## Phase 3 Success Criteria

| Criteria | Target |
|----------|--------|
| Widget active users | > 30% MAU |
| Shortcut usage | > 10% MAU |
| Premium conversion rate | > 5% free → paid |
| Family plan adoption | > 15% of paid users |
| Advanced AI feature usage | > 30% MAU |
| API active users | > 50 power users |

---

## Phase 3 Risks

| Risk | Mitigation |
|------|------------|
| REST API abuse / security | Rate limiting, API key rotation, usage monitoring |
| StoreKit rejection for pricing | Use standard price tiers ($0.99, $4.99, $9.99) |
| Google Drive OAuth complexity | Use AppAuth library, test all OAuth flows |