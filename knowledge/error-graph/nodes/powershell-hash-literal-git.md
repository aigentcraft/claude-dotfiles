---
title: "PowerShell Hash Table Literal parsing in Git commands"
description: "Using git @{u} syntax in PowerShell scripts causes a ParserError because PowerShell interprets it as an empty hash table literal."
type: "technical-error"
tags: ["powershell", "git", "syntax-error"]
---

## 1. Plan / Context
We were writing a PS1 script (`sync.ps1`) to automatically fetch and compare the local Git branch against its upstream counterpart to trigger an auto-synchronization.

## 2. Do / The Error
We wrote the standard Git command to get the remote tracking branch:
`$remote = git rev-parse @{u} 2>$null`

When executing the script, PowerShell threw a fatal `ParserError`:
```
ParserError: C:\Users\user\.gemini\antigravity\scripts\sync.ps1:93:36
     |                                     ~       
     | literal.
```

## 3. Check / Root Cause
In standard Bash or CMD, `@` and curly braces are treated as string characters unless explicitly evaluated. However, in PowerShell, the sequence `@{ ... }` is the native syntax for creating a **Hash Table Literal** (similar to a dictionary/object). PowerShell intercepted the `@{u}` argument meant for Git, tried to parse it as a hash table, failed because `u` is not a valid key-value definition, and crashed the script before Git even executed.

## 4. Act / Prevention Strategy (Fix)
**Fix Applied**: We enclosed the argument in double-quotes to force PowerShell to treat it as a pure string literal before passing it to Git:
`$remote = git rev-parse "@{u}" 2>$null`

**Future AI Instruction**: When writing or modifying PowerShell (`.ps1`) scripts that call external CLI tools (like `git`, `docker`, `npm`), be extremely cautious with special characters. **ALWAYS quote arguments containing `@`, `{`, `}`, `$`, `(`, or `)`**. PowerShell's parser is highly aggressive and will attempt to evaluate these as native PS objects, variables, or expressions unless explicitly told they are strings.
