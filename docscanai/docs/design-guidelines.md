# DocScan AI — Design Guidelines
**Version:** 1.0 | **Target:** iOS 16.4+ | iPhone + iPad

---

## 1. Design System

### Color Palette

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| Primary | `#007AFF` | `#0A84FF` | Buttons, links, accents |
| Secondary | `#5856D6` | `#5E5CE6` | AI features, chat |
| Success | `#34C759` | `#30D158` | Scan complete, save success |
| Warning | `#FF9500` | `#FF9F0A` | AI processing |
| Destructive | `#FF3B30` | `#FF453A` | Delete, errors |
| Background | `#F2F2F7` | `#000000` | App background |
| Surface | `#FFFFFF` | `#1C1C1E` | Cards, sheets |
| Surface Secondary | `#E5E5EA` | `#2C2C2E` | Grouped backgrounds |
| Text Primary | `#000000` | `#FFFFFF` | Main text |
| Text Secondary | `#8E8E93` | `#8E8E93` | Captions, metadata |
| Border | `#C6C6C8` | `#38383A` | Dividers |

### Typography

| Style | Font | Size | Weight | Line Height |
|-------|------|------|--------|-------------|
| Large Title | SF Pro Display | 34pt | Bold | 41pt |
| Title 1 | SF Pro Display | 28pt | Bold | 34pt |
| Title 2 | SF Pro Display | 22pt | Bold | 28pt |
| Title 3 | SF Pro Display | 20pt | Semibold | 25pt |
| Headline | SF Pro Text | 17pt | Semibold | 22pt |
| Body | SF Pro Text | 17pt | Regular | 22pt |
| Callout | SF Pro Text | 16pt | Regular | 21pt |
| Subheadline | SF Pro Text | 15pt | Regular | 20pt |
| Footnote | SF Pro Text | 13pt | Regular | 18pt |
| Caption 1 | SF Pro Text | 12pt | Regular | 16pt |
| Caption 2 | SF Pro Text | 11pt | Regular | 13pt |

### Spacing System (8pt Grid)

| Token | Value | Usage |
|-------|-------|-------|
| `spacing-xs` | 4pt | Inline icon gaps |
| `spacing-sm` | 8pt | Tight padding |
| `spacing-md` | 16pt | Standard padding |
| `spacing-lg` | 24pt | Section spacing |
| `spacing-xl` | 32pt | Major sections |
| `spacing-2xl` | 48pt | Screen padding top |

### Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-sm` | 8pt | Buttons, small cards |
| `radius-md` | 12pt | Cards, sheets |
| `radius-lg` | 16pt | Large cards |
| `radius-full` | 9999pt | Pills, circular |

### Shadows

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `shadow-sm` | 0 1px 2px rgba(0,0,0,0.1) | none | Subtle elevation |
| `shadow-md` | 0 4px 12px rgba(0,0,0,0.1) | none | Cards |
| `shadow-lg` | 0 8px 24px rgba(0,0,0,0.15) | none | Modals |

---

## 2. Screen Designs

### Screen 1 — Scan (Home Tab)

**Layout:**
- Full-screen gradient background (#F2F2F7 → white)
- Center: Large doc.viewfinder icon (80pt, secondary color)
- Title: "Quét tài liệu" (Title 1)
- Subtitle: 2 lines, centered (Body, secondary)
- CTA button: Full-width, 50pt height, Primary blue, radius-lg
- Secondary button: Full-width, 50pt, Surface Secondary, radius-lg
- Buttons pinned to bottom safe area + 32pt padding

**Elements:**
- Scan button: "Quét ngay" + viewfinder icon (SF Symbol)
- Import button: "Nhập từ Photos" + photo.on.rectangle icon
- Empty state hint: Camera icon + "Camera not available" if unsupported

### Screen 2 — Library

**Layout:**
- Navigation bar: Large title "Thư viện"
- Segmented control below nav bar: "Lưới" | "Danh sách"
- Content: Grid (2 columns) or List
- Empty state: Centered icon + message

**Grid Cell (150×220pt):**
- Thumbnail: 12pt padding, aspect 3:4, radius-md
- Title: 2 lines max, Footnote semibold
- Meta: "X trang • date", Caption 2, secondary
- Favorite star: 14pt, top-right corner

**List Cell (full-width × 80pt):**
- Icon: 44×60pt, left, radius-sm
- Title: Body, 1 line
- Meta: Caption 1, secondary
- Chevron: right, tertiary

**Context Menu:**
- Favorite / Unfavorite
- Delete (destructive)

### Screen 3 — Document Detail (PDF Viewer + Chat)

**Layout — Split view:**
- PDF View: 60% width (iPad: 65%)
- Chat Panel: 40% width (iPad: 35%)
- Chat toggle via toolbar button

**PDF Viewer:**
- PDFView with auto-scale
- Navigation bar: Title (inline), toolbar right
- Toolbar: Chat toggle | Annotate | Share | More (...)
- Bottom: Page indicator

**Chat Panel:**
- Header: 50pt, "AI Chat" + brain icon, blue
- Message list: Bubble style
- User bubble: Primary blue, white text, right-aligned
- AI bubble: Secondary bg, left-aligned
- Quick actions bar: 44pt, "Tóm tắt" | "Dịch"
- Input: TextField + send button

### Screen 4 — Settings

**Layout:** Standard UITableView insetGrouped
- Section: AI Configuration — API Key row
- Section: Bảo mật — App lock toggle
- Section: Tùy chỉnh — Haptic toggle, Language picker
- Section: Về ứng dụng — Version, iOS minimum

---

## 3. Component Library

### Primary Button
```
Height: 50pt | Padding: 16pt horizontal
Background: Primary (#007AFF)
Text: 17pt Semibold, white
Icon: 20pt, left of text, 8pt gap
Radius: 12pt (radius-lg)
Haptic: mediumImpact on tap
States: default, pressed (opacity 0.8), disabled (opacity 0.5)
```

### Secondary Button
```
Background: Surface Secondary (#E5E5EA dark: #2C2C2E)
Text: 17pt Semibold, label color
Icon: 20pt, left of text, 8pt gap
Radius: 12pt
```

### Chat Bubble
```
User: Background #007AFF, text white, radius 16pt, max-width 80%
      Padding: 12pt horizontal, 8pt vertical
      Time: Caption 2, tertiary, below bubble, 4pt margin
AI: Background #E5E5EA (dark: #2C2C2E), text label, same sizing
```

### Document Card
```
Background: Surface Secondary
Radius: 12pt
Padding: 12pt
Thumbnail: aspect 3:4, radius 8pt
Shadow: shadow-sm
```

### Quick Action Pill
```
Background: Primary @ 10% opacity
Text: Caption, Primary color
Icon: Caption, left
Padding: 8pt horizontal, 6pt vertical
Radius: 16pt (radius-full)
```

---

## 4. Animations & Transitions

| Action | Animation |
|--------|-----------|
| Tab switch | Cross-dissolve, 200ms |
| Sheet present | Spring: response 0.3, damping 0.8 |
| Chat panel toggle | Spring: response 0.3, damping 0.8 |
| Scan capture | Haptic: rigid + flash overlay 100ms |
| Message send | Scale 0.95→1, opacity 0→1, 200ms |
| AI thinking | Pulsing dots animation |
| Page load | Fade in 150ms |
| Success | Haptic: success + checkmark |

### Haptic Patterns
- `scanCapture`: rigid impact × 2 (10ms apart)
- `messageSent`: soft impact
- `aiThinking`: light impact × 3 (200ms apart)
- `buttonTap`: medium impact
- `success`: notification success
- `error`: notification error

---

## 5. Accessibility

- All text: Dynamic Type support (minimum Body)
- All buttons: minimum 44×44pt touch target
- Color contrast: WCAG AA (4.5:1 for text)
- VoiceOver: labels for all interactive elements
- Reduce Motion: disable spring animations

---

## 6. Dark Mode

- All colors have dark mode equivalents (see palette)
- Surfaces use elevated dark tones
- No shadows in dark mode
- Chat bubbles: #2C2C2E (AI), Primary (user — stays blue)
