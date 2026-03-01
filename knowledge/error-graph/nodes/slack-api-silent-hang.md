---
title: "Slack API postMessage Silent Hang"
description: "Slack API chat.postMessage can sometimes hang indefinitely without throwing an error, causing MCP long-polling tools to block forever."
type: "technical-error"
tags: ["slack", "api", "timeout", "mcp"]
---

## 1. Plan / Context
We were building an MCP proxy server to send interactive Slack messages (`chat.postMessage`) using `@slack/bolt`. The goal was to wait for user approval via Slack buttons and return the result to the AI.

## 2. Do / The Error
The test script called the MCP tool, which in turn called `slackApp.client.chat.postMessage`. However, the API call simply hung forever. It didn't resolve, and it didn't throw an error. Because the MCP tool awaited this call, the entire test script and the AI tool execution blocked indefinitely. Terminating the script and restarting didn't yield an immediate error object.

## 3. Check / Root Cause
Network requests to Slack's API (or Bolt's internal socket mode connection) can occasionally get stuck in a pending state, especially if the underlying connection drops silently or if the proxy server restarts and loses tracked socket state. Without an explicit timeout, `await` on these network calls will freeze the execution context forever.

## 4. Act / Prevention Strategy (Fix)
**Fix Applied**: We wrapped the `postMessage` call in a `Promise.race` alongside a manual `setTimeout` rejection promise. This forced the operation to fail after 10 seconds, exposing the actual underlying error behavior instead of hanging indefinitely.

**Future AI Instruction**: Whenever calling external web APIs (like Slack, GitHub, or any remote service) inside an MCP tool or long-running script, **NEVER** trust `await` blindly. **ALWAYS** implement a fallback timeout (e.g., using `Promise.race`) or configure the HTTP client's native timeout properties. This prevents silent hangs and ensures the system fails fast and returns useful logs.
