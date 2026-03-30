# Phase 1 — MVP: Scan + AI Chat
**Ngày:** 2026-03-30 | **Độ ưu tiên:** 🔴 CRITICAL

---

## Tổng quan

| Mục | Chi tiết |
|-----|----------|
| **Thời gian** | 0–3 tháng (tuần 1–12) |
| **Mục tiêu** | App Store ready — scan tài liệu, AI chat tương tác |
| **Groups** | 1, 2, 3, 4 |
| **Developer weeks** | ~10 weeks tổng (3+2+2+3) |
| **Designer weeks** | ~8 weeks tổng |

**Cut from MVP if needed:**
- Multi-page scan flow (v1.0 chỉ single scan) → thêm tuần 11–12
- Handwritten signature → dùng type-to-sign trước
- Table/chart recognition → text-only OCR trước

---

## Group 1 — Scan & Import

### 1.1 Mô tả
Camera scan với auto-crop và perspective correction bằng VisionKit. Import từ Photos, Files app.

### 1.2 User Stories
- *"As a office worker, I want to scan receipts in 2 taps so that I can archive them before the deadline"*
- *"As a student, I want to import my lecture notes from Photos so that I can organize them in one app"*
- *"As a accountant, I want multi-page scan so that I can digitize a full invoice in one session"*

### 1.3 MVP Scope
- Single-page scan với VNDocumentCameraViewController
- Auto-edge detection + perspective correction (tự động từ VisionKit)
- Import từ Photos library (PHPickerViewController)
- Import từ Files app (UIDocumentPickerViewController)
- Save as PDF to app sandbox

### 1.4 Tech Stack
- **VisionKit** — VNDocumentCameraViewController (auto-crop, multi-page)
- **PDFKit** — tạo PDF từ scanned images
- **PhotosUI** — PHPickerViewController
- **SwiftUI** + **UIKit interop** — scan preview + result

### 1.5 App Store Permissions
- `NSCameraUsageDescription` — **REQUIRED** (bắt buộc mô tả rõ: "Scan documents")
- `NSPhotoLibraryUsageDescription` — import ảnh

### 1.6 Implementation Steps

```
Step 1.1: Setup VisionKit document camera
  File: ScanView.swift
  - VNDocumentCameraViewController delegate
  - Handle scanned images as [UIImage]
  - Thumbnail preview grid

Step 1.2: Build PDF generation
  File: PDFGenerator.swift
  - Convert [UIImage] → PDFDocument (PDFKit)
  - Save to app Documents directory
  - Generate thumbnail for library

Step 1.3: Implement Photos import
  File: PhotoImportView.swift
  - PHPickerViewController single selection
  - Convert to PDF same as scan

Step 1.4: Implement Files import
  File: FilesImportView.swift
  - UIDocumentPickerViewController for PDF + images
  - Copy to app sandbox

Step 1.5: Scan flow UX
  File: ScanFlowView.swift
  - Camera → Preview → Confirm → Save
  - Haptic feedback on capture (UIImpactFeedbackGenerator)
  - Page count badge
```

### 1.7 Effort: 3 weeks

---

## Group 2 — AI Document Processing

### 2.1 Mô tả
OCR on-device bằng Vision framework → gửi text lên Claude API để extract structured data.

### 2.2 User Stories
- *"As a accountant, I want AI extract invoice numbers and amounts so that I don't type them manually"*
- *"As a lawyer, I want multi-language OCR (Vietnamese + English) so that I can process bilingual contracts"*
- *"As a HR manager, I want date/number field extraction so that I can batch-process contracts"*

### 2.3 MVP Scope
- OCR on-device: VNRecognizeTextRequest (Vietnamese + English primary)
- Extract structured fields: dates, numbers, names (regex + Claude)
- Store extracted text alongside PDF for search
- Background processing với async/await

### 2.4 Tech Stack
- **Vision** — VNRecognizeTextRequest (on-device)
- **Claude API** — structured extraction via JSON mode
- **Swift Concurrency** — async/await background processing

### 2.5 App Store Considerations
- Cloud API calls = cần privacy policy URL trên App Store Connect
- Document images sent to cloud → cần mô tả rõ in privacy policy

### 2.6 Implementation Steps

```
Step 2.1: Vision OCR pipeline
  File: OCRService.swift
  - VNRecognizeTextRequest with revision 4
  - Set recognitionLanguages: ["vi", "en", "zh-Hans"]
  - Confidence threshold: 0.5
  - Return recognized text blocks with bounding boxes

Step 2.2: Claude structured extraction
  File: AIDocumentProcessor.swift
  - Send OCR text + PDF page images to Claude
  - Use JSON mode response schema:
    {
      "invoice_number": string,
      "dates": string[],
      "amounts": string[],
      "names": string[],
      "summary": string
    }
  - Store in Swift Data model

Step 2.3: Background processing queue
  File: ProcessingQueue.swift
  - AsyncQueue for parallel OCR
  - Progress indicator in document detail
  - Retry on failure (3 attempts, exponential backoff)

Step 2.4: Page-level storage
  File: DocumentPage.swift (Swift Data model)
  - pageNumber: Int
  - rawText: String
  - extractedData: ExtractedData (Codable)
  - processingStatus: Enum (pending/processing/done/failed)
```

### 2.7 Effort: 2 weeks

---

## Group 3 — Edit & Annotate

### 3.1 Mô tả
Annotation layer trên PDF: highlight, underline, strikethrough, digital signature, form fill.

### 3.3 MVP Scope
- Highlight, underline, strikethrough (PDFKit annotation)
- Type-to-sign signature (text with styling)
- Save annotated PDF

### 3.4 Cut from MVP
- Handwritten signature (PencilKit) → Phase 2
- Form field fill → Phase 2 (complex PDF form parsing)

### 3.5 Tech Stack
- **PDFKit** — PDFAnnotation subclasses
- **Core Graphics** — custom drawing

### 3.6 Implementation Steps

```
Step 3.1: Annotation toolbar
  File: AnnotationToolbar.swift
  - Tool buttons: highlight (yellow), underline, strikethrough, eraser
  - Selected color swatches
  - Active tool state management

Step 3.2: Highlight/underline/strikethrough
  File: AnnotationManager.swift
  - PDFAnnotation subclass: HighlightAnnotation, UnderlineAnnotation
  - Tap-to-select text → tap toolbar → apply annotation
  - Render on PDFPage with annotation layer

Step 3.3: Signature tool
  File: SignatureView.swift
  - Text input with cursive font styling
  - Position signature on PDF page
  - Save as signature annotation with appearance stream

Step 3.4: PDF save
  File: DocumentEditorView.swift
  - Save annotated PDF to Documents directory
  - Version tracking (overwrite v1, v2 increments)
```

### 3.7 Effort: 2 weeks

---

## Group 4 — AI Chat with Document

### 4.1 Mô tả
Chat panel tích hợp trong document viewer. Người dùng hỏi → AI trả lời với citations (page number references).

### 4.2 User Stories
- *"As a employee, I want to ask 'What is the payment deadline?' so that I get an instant answer from the contract"*
- *"As a student, I want one-tap summary of pages 2–3 so that I can review quickly before exam"*
- *"As a manager, I want to translate page 5 to English so that I can share with foreign partners"*

### 4.3 MVP Scope
- Chat panel trong document viewer (slide-up sheet)
- Ask free-text questions → Claude API trả lời
- Summary button (tóm tắt full document hoặc selected pages)
- Inline translate (page-level, source → target language)
- Cited answers (AI ghi "Như trang 2 đoạn 3")

### 4.4 Tech Stack
- **SwiftUI** — chat interface (ChatView, MessageBubble)
- **Claude API** — Anthropic Messages API
- **Swift Data** — store chat history per document

### 4.5 App Store Review Note
- AI chat = "Artificial Intelligence" feature → Apple yêu cầu disclosure
- Thêm flag `hasAIIntelligenceFeature: true` trong App Store Connect metadata

### 4.6 Implementation Steps

```
Step 4.1: Chat UI
  File: DocumentChatView.swift (SwiftUI)
  - Sheet presentation từ document viewer
  - Messages list (user bubbles right, AI bubbles left)
  - Input field với send button
  - "Summarize" + "Translate" quick action buttons

Step 4.2: Message model + storage
  File: ChatMessage.swift (Swift Data)
  - id: UUID
  - documentId: UUID
  - role: Enum (user/assistant/system)
  - content: String
  - pageReferences: [PageReference]
  - timestamp: Date

Step 4.3: Claude API integration
  File: ClaudeChatService.swift
  - System prompt: "You are a document assistant. Answer based on the provided document context. Always cite page numbers."
  - Attach OCR text as context (chunked by page, ~4000 tokens/page)
  - Stream responses with AsyncStream<String>
  - Implement citation parsing (regex: "trang X", "page X")

Step 4.4: Summary feature
  File: SummaryService.swift
  - Button: "Tóm tắt tài liệu"
  - Claude: generate 3–5 bullet summary
  - Show in dedicated sheet, not chat stream

Step 4.5: Translate feature
  File: TranslateService.swift
  - Language selector (Vietnamese, English, Chinese)
  - Translate selected page or full document
  - Return translated text block

Step 4.6: Streaming UI
  File: StreamingMessageView.swift
  - Show AI response as it streams (character-by-character)
  - "Thinking..." placeholder while processing
  - Typing indicator animation
```

### 4.7 Effort: 3 weeks

---

## Phase 1 Todo List

- [ ] Setup project XcodeGen + SPM dependencies
- [ ] Group 1: VisionKit scan (3w)
- [ ] Group 2: Vision OCR + Claude extraction (2w)
- [ ] Group 3: PDF annotation tools (2w)
- [ ] Group 4: Chat UI + Claude API + streaming (3w)
- [ ] UI polish + haptics + animations
- [ ] Permission flow testing (camera, photo library)
- [ ] Privacy policy URL ready (required for AI features)
- [ ] App Store Connect metadata: AI disclosure flag

---

## Phase 1 Success Criteria

| Criteria | Target |
|----------|--------|
| Scan → PDF completion | < 10s |
| OCR processing per page | < 3s |
| AI chat response time | < 5s (streaming starts < 2s) |
| App launch time | < 1.5s |
| Memory usage during scan | < 150MB |
| App Store rating at launch | ≥ 4.5★ |

---

## Phase 1 Key Dependencies

```
VisionKit → PDFKit → Swift Data
Vision OCR → Claude API → Chat UI
All via SwiftUI + async/await
```

## Phase 1 Risks

| Risk | Mitigation |
|------|------------|
| VNDocumentCameraViewController fails on iPad | Test on both form factors |
| Claude API rate limits | Implement token budgeting, cache responses |
| PDF annotation conflict with Apple Pencil | Test PencilKit coexistence |