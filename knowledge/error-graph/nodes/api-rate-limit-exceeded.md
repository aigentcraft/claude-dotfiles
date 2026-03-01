---
title: "Mock Test: API Rate Limit Exceeded"
description: "Third-party API returned 429 Too Many Requests due to lack of throttling. Implemented exponential backoff."
type: "technical-error"
tags: ["api", "network", "rate-limit"]
---

## 1. Plan / Context
Attempted to scrape 100 pages concurrently from a single domain without any delay between requests.

## 2. Do / The Error
The API returned status code `429 Too Many Requests`. The system crashed because it did not handle the non-200 response gracefully.

## 3. Check / Root Cause
The code lacked request throttling and error handling for 4xx status codes. It assumed all network requests would succeed immediately.

## 4. Act / Prevention Strategy (Fix)
**Fix:** Added an exponential backoff retry wrapper around the network request function and limited concurrency to 5.
**Prevention:** Whenever writing network request logic, ALWAYS implement a retry mechanism (e.g., exponential backoff) and validate the response status code before parsing the body. Do not default to unbounded concurrent requests against a single domain.
