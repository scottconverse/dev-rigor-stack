# Security Policy

## What this project is, security-wise

dev-rigor-stack installs Markdown skills and three small Node hook scripts that run
locally on every Claude Code session (`SessionStart`, `UserPromptSubmit`,
`PostToolUse`, `Stop`). The hooks:

- read only files inside the repo/plugin directory and a per-session state directory
  under `~/.claude/dev-rigor-plugin/state/` (session IDs are sanitized before touching
  the filesystem);
- never make network calls, never eval/execute injected text, and have zero runtime
  dependencies (Node built-ins only);
- fail open — any internal error degrades to silence rather than blocking or breaking
  a session;
- modify exactly one file outside their own directory: `settings.json`, idempotently,
  refusing (exit 1, file untouched) if it is corrupt or unexpectedly shaped.

## Supported versions

The latest tagged release. Older tags get no backports — upgrading is a re-run of the
installer.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting on this repository ("Report a
vulnerability" under the Security tab), or open a plain issue if the report isn't
sensitive. Include the narrowest reproduction you have. You'll get an acknowledgment
and a fix-or-explanation — this project's own rules forbid shipping past a known
security finding.
