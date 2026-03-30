# Phase 2 — Growth: Library + Security + Collaboration
**Ngày:** 2026-03-30 | **Độ ưu tiên:** 🟡 MEDIUM-HIGH

---

## Tổng quan

| Mục | Chi tiết |
|-----|----------|
| **Thời gian** | 3–6 tháng (tuần 13–24) |
| **Mục tiêu** | Quản lý thư viện, bảo mật, cộng tác nhóm |
| **Groups** | 5, 6, 7, 8 |
| **Developer weeks** | ~9 weeks tổng (2+1+2+4) |
| **Designer weeks** | ~6 weeks tổng |

---

## Group 5 — Library Management

### 5.1 Mô tả
Tổ chức tài liệu theo folder, collection. AI auto-tag và semantic search.

### 5.2 User Stories
- *"As a lawyer, I want to organize contracts by client folders so that I can find them within seconds"*
- *"As a student, I want AI auto-tag my lecture notes so that I can search 'history' and find all history-related docs"*
- *"As a accountant, I want semantic search so that searching 'quarterly tax report' finds Q1 tax document"*

### 5.3 MVP Scope (Phase 2)
- Folder hierarchy (create, rename, move, delete)
- Favorites / Recently viewed
- AI auto-tagging (document type: invoice, contract, note, ID card)
- Keyword search (stored OCR text)
- Semantic search (Claude embeddings — FAISS-like vector search)

### 5.4 Tech Stack
- **Swift Data** — Document, Folder, Tag models
- **Core Spotlight** — Search indexing for keyword search
- **Claude Embeddings API** — semantic vector storage (local SQLite extension)
- **Swift Collections** — Deque for recents

### 5.5 Implementation Steps

```
Step 5.1: Data models
  File: Models.swift (Swift Data)
  - Document: id, title, pdfData, folder, tags, createdAt, lastOpened
  - Folder: id, name, parentFolder, children[]
  - Tag: id, name, type (Enum: invoice/contract/note/idcard/other)
  - Index: fullText (concatenated OCR text)

Step 5.2: Folder management UI
  File: LibraryView.swift (SwiftUI)
  - NavigationSplitView (sidebar for iPad, list for iPhone)
  - Create/delete folder actions
  - Drag-and-drop to move documents

Step 5.3: AI auto-tagging
  File: AutoTagService.swift
  - On document import: send first page to Claude
  - Prompt: "Classify this document type: invoice | contract | note | idcard | other"
  - Store tag in Tag model
  - Update Spotlight index

Step 5.4: Semantic search
  File: SemanticSearchService.swift
  - Embed document text chunks via Claude Embeddings API
  - Store vectors in local array (phase 1 simplicity)
  - Phase 3: integrate SQLite Vector extension for production scale
  - Query: embed user text → cosine similarity → rank results
```

### 5.6 Effort: 2 weeks

---

## Group 6 — Export & Share

### 6.1 Mô tả
Export PDF, Word, CSV. Share link với expiry.

### 6.2 User Stories
- *"As a accountant, I want to export to CSV so that I can import invoice data into Excel"*
- *"As a manager, I want to share a link that expires in 7 days so that I control document access"*

### 6.3 MVP Scope
- Export: PDF (original), plain text, CSV (extracted data)
- Share: UIActivityViewController (AirDrop, email, Messages)
- Share link: generate short URL (backend required) → Phase 3 (Phase 2: AirDrop + email only)

### 6.4 Tech Stack
- **PDFKit** — export PDF
- **UIActivityViewController** — system share sheet
- **UIDocumentInteractionController** — preview before share

### 6.5 Implementation Steps

```
Step 6.1: Export services
  File: ExportService.swift
  - exportAsPDF() — return PDFDocument data
  - exportAsText() — concatenate all OCR text
  - exportAsCSV() — extract structured fields to CSV rows

Step 6.2: Share sheet integration
  File: ShareSheetView.swift
  - UIActivityViewController wrapper
  - Exclude: Print (Phase 3), Files app save (Phase 2)

Step 6.3: Print support
  File: PrintService.swift
  - UIPrintInteractionController
  - AirPrint auto-discovery
```

### 6.6 Effort: 1 week

---

## Group 7 — Security

### 7.1 Mô tả
Face ID/Touch ID lock, end-to-end encryption, password-protected PDFs.

### 7.2 User Stories
- *"As a doctor, I want Face ID lock per sensitive document so that patient records are protected"*
- *"As a enterprise user, I want end-to-end encryption so that my documents can't be read by the cloud provider"*
- *"As a lawyer, I want password-protected PDFs so that I can send confidential contracts safely"*

### 7.3 MVP Scope
- Face ID / Touch ID app lock (LocalAuthentication)
- Password-protected PDF export (CGPDFDocument with encryption)
- Optional: document-level biometric lock (store encrypted key in Keychain)

### 7.4 Cut from Phase 2
- End-to-end encryption for cloud sync → Phase 3 (CloudKit E2E setup phức tạp)

### 7.5 Tech Stack
- **LocalAuthentication** — LAContext for Face ID/Touch ID
- **CryptoKit** — AES-GCM encryption for sensitive fields
- **PDFKit** — CGPDFDocument with owner password
- **Keychain** — store encrypted document keys

### 7.6 App Store Permissions
- `NSFaceIDUsageDescription` — **REQUIRED** ("Unlock your documents with Face ID")

### 7.7 App Store Review Note
- Face ID usage description bị Apple reject thường xuyên → phải mô tả cụ thể use case, không generic

### 7.8 Implementation Steps

```
Step 7.1: App lock
  File: BiometricLockManager.swift
  - LAContext evaluatePolicy for app-wide lock
  - Lock screen on app background (>30s in background)
  - Fallback to device passcode

Step 7.2: Per-document lock
  File: DocumentLockService.swift
  - Encrypt PDF data with AES-256-GCM (CryptoKit)
  - Store encryption key in Keychain per document
  - Require biometric to unlock → decrypt → display

Step 7.3: Password-protected PDF export
  File: PDFEncryptionService.swift
  - Use CGPDFDocument with owner/user password
  - Allow printing but not copying with user password
  - Full restriction with owner password

Step 7.4: Secure storage
  File: SecureStorage.swift
  - Keychain wrapper for document encryption keys
  - Store metadata (not PDF data) encrypted at rest
```

### 7.9 Effort: 2 weeks

---

## Group 8 — Team Collaboration

### 8.1 Mô tả
Real-time comments, access permissions, version history trên shared documents.

### 8.2 User Stories
- *"As a project manager, I want to comment on specific pages so that the team knows which sections need revision"*
- *"As a team lead, I want view/edit/admin permissions so that I control who can modify documents"*
- *"As a writer, I want version history so that I can restore a paragraph I accidentally deleted"*

### 8.3 MVP Scope
- Comment threads (page-level, text comments)
- Access permissions: view-only / edit (local only, Phase 2)
- Version history (local document snapshots)
- Share via link: CloudKit share (CKShare) → Phase 3

### 8.4 Tech Stack
- **CloudKit** — CKContainer, CKShare for real-time collaboration
- **Swift Data** — Comment, Version models
- **Combine** — real-time update propagation

### 8.5 App Store Permissions
- `NSUbiquitousContainersUsageDescription` — iCloud access
- CloudKit container must be created in Apple Developer Portal before development

### 8.6 App Store Review Note
- CloudKit collaboration = "Data in Cloud" category → Apple requires privacy nutrition labels

### 8.7 Implementation Steps

```
Step 8.1: Comment models
  File: Comment.swift (Swift Data)
  - Comment: id, documentId, pageNumber, text, authorName, timestamp
  - CommentThread: id, comments[], resolved: Bool
  - Anchor: pageNumber + CGRect for page-anchored comments

Step 8.2: Comment UI
  File: CommentPanelView.swift (SwiftUI)
  - Floating comment icon per page (like PDF Expert)
  - Thread list sidebar
  - Reply + resolve actions

Step 8.3: Version history
  File: VersionHistoryService.swift
  - Auto-save snapshot on each save (limit: last 10 versions)
  - Store diff snapshots (not full PDFs) to save space
  - Restore: merge diff back to current

Step 8.4: Permission model
  File: DocumentPermission.swift
  - Enum: viewOnly, edit, admin
  - Store in document metadata
  - Enforce UI accordingly (hide edit tools for viewOnly)

Step 8.5: CloudKit share
  File: CollaborationService.swift
  - CKShare per document
  - UICloudSharingController for share UI
  - Accept/decline via CloudKit notifications
  - Conflict resolution: last-write-wins (MVP)
```

### 8.8 Effort: 4 weeks (highest effort group)

---

## Phase 2 Todo List

- [ ] Group 5: Library + folders + AI tagging + semantic search (2w)
- [ ] Group 6: Export + share sheet (1w)
- [ ] Group 7: Biometric lock + PDF encryption (2w)
- [ ] Group 8: Comments + version history + CloudKit share (4w)
- [ ] CloudKit container setup (Apple Developer Portal)
- [ ] iCloud entitlement provisioning
- [ ] Privacy nutrition labels update
- [ ] iPad adaptive UI (NavigationSplitView)

---

## Phase 2 Success Criteria

| Criteria | Target |
|----------|--------|
| Library usage rate | > 60% users create folders |
| Search relevance (keyword) | > 80% top-3 results correct |
| Semantic search accuracy | > 70% top-3 results relevant |
| Biometric unlock success | > 95% |
| Collaboration sessions | > 200 active shared documents |
| Version restore success | 100% (critical path) |

---

## Phase 2 Risks

| Risk | Mitigation |
|------|------------|
| CloudKit sync conflicts complex | Use NSPersistentCloudKitContainer defaults, last-write-wins |
| Face ID description rejection | Use exact phrase: "Unlock your documents securely" |
| Semantic search accuracy poor | Start keyword-only, add embeddings in Phase 3 |