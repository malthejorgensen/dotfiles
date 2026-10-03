workspace-write vs. malthe-sandbox
----------------------------------

The standard mode in Codex is called workspace-write:

 Access                                Standard workspace-write             Your malthe-sandbox
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Reads outside the project             Broadly allowed, subject to OS       Denied except explicitly allowed
                                       permissions                          directories
────────────────────────────────────  ───────────────────────────────────  ───────────────────────────────────
 Project edits                         Allowed                              Allowed
────────────────────────────────────  ───────────────────────────────────  ───────────────────────────────────
 Temporary-directory writes            Allowed                              Allowed
────────────────────────────────────  ───────────────────────────────────  ───────────────────────────────────
 Package-cache writes outside          Usually require additional           Allowed in your listed caches
 project                               permission
────────────────────────────────────  ───────────────────────────────────  ───────────────────────────────────
 Reading                               Allowed by the sandbox               Denied
 project .env, .plans, .prompts
────────────────────────────────────  ───────────────────────────────────  ───────────────────────────────────
 Command network access                Off by default                       Enabled with your domain
                                                                            allowlist

Standard workspace-write still protects workspace .git, .codex, and .agents directories against modification.
Its default read access is unrestricted; its main filesystem restriction concerns where commands can write.
Read-access defaults (https://learn.chatgpt.com/docs/app-server#sandbox-read-access-readonlyaccess), sandbox
protections and networking (https://learn.chatgpt.com/docs/agent-approvals-security).

