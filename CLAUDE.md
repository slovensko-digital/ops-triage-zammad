# ops-triage-zammad

Triage: the Zammad where volunteers review portal issues and route them to the
responsible subject. Customisations live in `zammad/` (migrations, `lib/ops/*`
patches, jobs) and `hacks/`.

## How it works docs

The flows between the portal, Triage and Backoffice are documented in
[`ops-portal/docs/how-it-works/`](https://github.com/slovensko-digital/ops-portal/tree/main/docs/how-it-works).
When you change a flow here, open a PR in `ops-portal` that updates the
matching file:

| Change | Doc |
|---|---|
| triggers, webhooks, `ops_state`, routing (700 rules), core workflows | `03-submission-and-triage.md`, `02-issue-lifecycle.md` |
| responsible subject change, R/U tickets | `04-resolution.md` |
| article or user webhooks (`zammad/app/jobs/*`, `zammad/lib/ops/*`) | `06-comments-likes-routing.md` |
| trigger emails, notification patches | `09-emails.md` |
| schedulers | `10-scheduled.md` |
| roles, groups, users | `08-onboarding.md` |

Triggers and rules changed in the Zammad admin UI count too: they are not in
this repo, so the docs are their only record.
