---
id: job-matching
type: moc
description: "Job matching & HR projects (2): deep-job-researcher, hb-job-matcher"
---
# Job Matching

Two projects focused on matching candidates to job opportunities. Both use [[pattern-scrape-then-llm]] to extract job data and apply AI-powered matching, but differ in their input methods and matching sophistication.

## Projects

### deep-job-researcher
- **Path**: `~/hyperbrowser-app-examples/deep-job-researcher/`
- **What it does**: Takes a resume and scrapes job boards to find matching positions, analyzing fit scores.
- **SDK APIs**: [[sdk-scrape-api]]
- **Key patterns**: [[pattern-scrape-then-llm]], [[pattern-multi-url-research]]
- **Use when**: You need resume-to-job matching from scraped job listings.

### hb-job-matcher
- **Path**: `~/hyperbrowser-app-examples/hb-job-matcher/`
- **What it does**: Extracts professional profile from a portfolio URL, then scrapes job boards to find best matches.
- **SDK APIs**: [[sdk-scrape-api]], [[sdk-extract-api]]
- **Key patterns**: [[pattern-structured-extraction]], [[pattern-scrape-then-llm]]
- **Use when**: You want to match a portfolio/profile URL directly to job opportunities.

## Common Patterns

Both projects share the resume/profile → scrape jobs → LLM match pipeline. The key difference: deep-job-researcher takes a traditional resume as input, while hb-job-matcher uses [[sdk-extract-api]] to first extract a structured profile from a portfolio URL, which demonstrates [[pattern-structured-extraction]] in a practical context.

## When to Use

Choose this cluster when the user mentions job searching, resume matching, hiring, or recruitment automation. For general research about companies (without job matching), see [[research-intelligence]] instead.
