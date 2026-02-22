---
id: sdk-extract-api
type: concept
description: "hb.extract.startAndWait() — prompt + JSON schema for structured data extraction"
---
# SDK: Extract API

The Extract API combines scraping with LLM-powered structured extraction. Instead of getting raw markdown/HTML and parsing it yourself, you provide a JSON schema describing the data you want, and the API returns typed data directly. This is ideal when you need specific fields rather than full page content.

## Signature

```typescript
const result = await hb.extract.startAndWait({
  urls: string[],
  schema: object,   // JSON Schema describing desired output
  prompt?: string,  // Optional instruction for the extraction LLM
});
// Returns: { data: T } where T matches the schema
```

## Options

| Parameter | Description |
|-----------|-------------|
| `urls` | Array of URLs to extract from (can be a single URL in an array) |
| `schema` | JSON Schema object defining the output structure |
| `prompt` | Optional natural language instruction guiding extraction |

## Examples

**Typed extraction** (from `hyperbuild/lib/hyperbrowser.ts`):
```typescript
export async function hbExtract<T>(params: {
  url: string;
  schema: object;
}): Promise<T | null> {
  const hb = getClient();
  const resp = await hb.extract.startAndWait({
    urls: [params.url],
    schema: params.schema as object,
  });
  return (resp?.data as T) ?? null;
}
```

This pattern wraps the API with TypeScript generics, so callers get typed data:
```typescript
interface CompanyInfo {
  name: string;
  description: string;
  features: string[];
}
const info = await hbExtract<CompanyInfo>({
  url: "https://example.com",
  schema: companyInfoSchema,
});
```

## Related

- [[sdk-scrape-api]] for when you need raw content instead of structured data
- [[pattern-structured-extraction]] for the full pattern including schema design
- [[agent-developer-tools]] — hyperbuild is the primary project demonstrating this API
