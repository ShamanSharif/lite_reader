# Lite Reader — Roadmap

A living list of improvements beyond the current feature set. Grouped by theme
and roughly ordered by value/effort. The architecture (Clean layers + repository
contract + cubits) is designed so each of these slots in without rewrites.

## Reading experience
- **True EPUB pagination.** `epub_view` is scroll-based. A real page-by-page
  EPUB needs a custom paginator (measure rendered text height, split into pages,
  PageView per page). Largest single effort; would make EPUB feel like the PDF
  "book" mode. Today EPUB offers chapter-by-chapter + TOC navigation instead.
- **Text selection + highlights.** Capture the selected passage in both engines
  to auto-fill notes/quote images and to store colored highlights. EPUB needs a
  selection-aware paragraph builder; PDF needs a text layer (pdfx exposes none —
  may require a different engine or OCR fallback).
- **In-book search.** Full-text search with result navigation (EPUB: search
  parsed paragraphs; PDF: needs an embedded text layer).
- **Dictionary / translate** on selected words.
- **Text-to-speech** with sentence highlighting (`flutter_tts`, API 21-safe).
- **Brightness + warmth slider**, margins, justification, font family picker
  (bundle a couple of OFL fonts).
- **Tap zones / volume-key page turn** in paginated mode.

## Library & organization
- **Tags / collections / shelves** and full-text search across title+author.
- **Metadata + cover extraction.** Parse EPUB OPF metadata (title/author/cover)
  and render the first PDF page as a thumbnail for real covers on the shelf.
- **Sort & view options** (recent, title, author, progress; grid/list toggle).
- **Background incremental scan** with a foreground service notification, and
  watch-folders that auto-import on change.
- **Reading statistics** (time read, streaks, pages/day) persisted per book.

## Sync & data
- **Annotation export/import** (Markdown/JSON) and share-all-notes.
- **Cloud backup / sync** of the Hive boxes (Drive/WebDAV) with conflict rules.
- **Per-book settings overrides** (e.g. a specific font size for one book).

## Platform & robustness
- **Android 13+ storage story.** `READ_EXTERNAL_STORAGE` is ineffective on API
  33+. Add a `READ_MEDIA_*` / `MANAGE_EXTERNAL_STORAGE` path, or fully embrace
  SAF directory trees (persisted URI permissions + a SAF-backed file reader) so
  scanning works on modern devices too.
- **Open-with hardening.** De-dupe re-opened files by content hash so opening
  the same attachment twice doesn't create duplicate library entries.
- **Debounced progress writes.** Currently every page/scroll change writes to
  Hive; batch on a timer to cut I/O.
- **Typed Hive adapters + schema migrations** if the data model grows.
- **Error/telemetry surface** and a proper logging layer.

## Quality
- **Widget/integration tests** for the reader engine switch, scan dedup, and the
  master–detail tablet layout (golden tests for the quote image).
- **Accessibility**: semantics labels, large-text support, screen-reader review.
- **Localization** (intl/ARB).
