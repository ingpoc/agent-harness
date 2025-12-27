---
name: browser-testing
description: Use when testing web applications, debugging browser console, automating form interactions, or verifying UI changes. Requires: Chrome extension 1.0.36+, Claude Code 2.0.73+, paid plan. Includes: live debugging, console log reading, GIF recording, authenticated app testing.
---

# Browser Testing Skill

Test and debug web applications directly from the terminal using Claude Code's Chrome integration.

## When to Use This Skill

Load this skill when you need to:
- Test local web applications (localhost:3000)
- Debug with browser console logs
- Verify UI implementations against designs
- Automate form filling and submission
- Test authenticated web apps (Gmail, Notion, Google Docs)
- Record demo GIFs of user flows
- Extract structured data from web pages
- Run multi-site workflows

## Prerequisites

| Requirement | Minimum Version |
|-------------|-----------------|
| Chrome extension | 1.0.36+ |
| Claude Code CLI | 2.0.73+ |
| Plan | Pro, Team, or Enterprise |
| Browser | Google Chrome |

## Additional Files

| File | When to Read | Content |
|------|--------------|---------|
| patterns.md | Designing test scenarios | Test patterns, debugging strategies |
| examples.md | Need concrete examples | Real-world test cases with prompts |

## Key Capabilities

| Capability | Description | Use Case |
|------------|-------------|----------|
| **Live debugging** | Read console errors, fix code | Console error → code fix |
| **Local testing** | Test localhost URLs | Development cycle |
| **Console reading** | Filter logs by pattern | Find ERROR/WARN messages |
| **Form automation** | Fill and submit forms | Data entry, testing |
| **Authenticated apps** | Uses browser login state | No API connectors needed |
| **GIF recording** | Record interactions | Demos, documentation |
| **Data extraction** | Pull structured info | Scrape, compile data |

## Quick Reference

| Task | Example Prompt |
|------|---------------|
| Test local app | "Open localhost:3000, submit form with invalid data" |
| Debug console | "Check console for errors on page load" |
| Verify UI | "Confirm the login form matches the Figma mock" |
| Fill forms | "Fill the contact form with data from contacts.csv" |
| Record demo | "Record GIF of checkout flow from cart to confirm" |

## Available Tools (via MCP)

Running `/mcp` and clicking `claude-in-chrome` shows:
- `computer` - Mouse/keyboard actions (click, type, scroll, screenshot)
- `navigate` - URL navigation
- `read_page` - Accessibility tree/DOM state
- `find` - Find elements by natural language
- `form_input` - Fill forms
- `read_console_messages` - Debug with pattern filtering
- `read_network_requests` - Monitor API calls
- `gif_creator` - Record sessions
- `tabs_context_mcp` - Get tab context

## Best Practices

1. **Avoid modal dialogs** - JavaScript alerts block browser events
2. **Use fresh tabs** - Claude creates new tabs each session
3. **Filter console output** - Specify patterns (ERROR, WARN) rather than "all logs"
4. **Test on localhost** - Perfect for development testing
5. **Handle blockers manually** - Login pages, CAPTCHAs - then tell Claude to continue

## Setup

First time setup:
```bash
claude --chrome
# Or in-session: /chrome
# Select "Enable by default" to skip --chrome flag
```

## Sources

- [Claude Code Chrome Documentation](https://code.claude.com/docs/en/chrome)
- [Claude in Chrome Extension](https://chrome.google.com/webstore/detail/claude-in-chrome/)
