---
id: concept-export-artifacts
type: concept
description: "Export formats: ZIP, PDF, JSONL, audio, etc."
---
# Concept: Export Artifacts

While most projects return JSON API responses, several generate downloadable file artifacts. The export format is often the key differentiator between projects in the same domain.

## Format Catalog

| Format | Technology | Projects |
|--------|-----------|----------|
| **JSON** | `NextResponse.json()` | Most projects (default) |
| **JSONL** | Line-delimited JSON | site-to-dataset (training data) |
| **ZIP** | archiver or JSZip | assets-optimizer (optimized assets) |
| **PDF** | pdf-lib, Puppeteer print | hb-pitchdeck (slide decks) |
| **Audio** | TTS APIs | podcast-generator-ai (podcast episodes) |
| **Markdown** | Raw text | hyperskills, skills-generator (SKILL.md files) |
| **HTML** | Generated pages | hyperpages (content pages) |
| **Postman Collection** | JSON spec format | scrape-to-api (API collections) |
| **Playwright Script** | TypeScript | flow-mapper (test scripts) |

## Generation Patterns

**File download via API route**:
```typescript
// Return binary file with appropriate headers
return new Response(zipBuffer, {
  headers: {
    'Content-Type': 'application/zip',
    'Content-Disposition': 'attachment; filename="assets.zip"',
  },
});
```

**Streamed text artifact** (most common for generated code):
```typescript
// Stream via SSE, client reconstructs
sendSSE({ type: 'code', content: generatedCode });
// Or return as JSON for client-side download
return NextResponse.json({ content: markdownContent, filename: 'SKILL.md' });
```

**Multi-step artifact** (hb-pitchdeck):
```
Scrape company → Extract structured data → Generate slides → Render PDF → Download
```

## Examples

The [[content-generation]] cluster demonstrates the most variety in export formats: HTML pages (hyperpages), PDF slides (hb-pitchdeck), and audio (podcast-generator-ai). The [[scraping-data-extraction]] cluster exports data in more structured formats: JSONL datasets (site-to-dataset), ZIP archives (assets-optimizer), and API collections (scrape-to-api).

When building a new project, choose the export format based on the consumer:
- **Developers**: JSONL, Markdown, code files
- **Business users**: PDF, HTML pages
- **Data pipelines**: JSON, JSONL
- **Presentations**: PDF, HTML
