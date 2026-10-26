# OPS Triage Zammad

## Local development

```
docker compose up -d --build
```

- Triage: http://localhost:8080 (`admin@example.org` / `PASSword123`). The first start runs `zammad-init`, which takes a few minutes.
- Volunteer (agent): `dobrovolnik@example.org` / `PASSword123`. The portal's `responsible_subjects:activate_basic` assigns municipalities to them, using the admin's `ADMIN_API_TOKEN`. `zammad-dev-setup` creates both (`dev/setup_users.rb`).
- Mailpit: http://localhost:8025. Every email Triage sends lands here, never in a real inbox (`dev/mail_catcher.rb`, mounted by `docker-compose.yml` only). Trigger emails (e.g. to responsible subjects) need an email channel, `zammad-dev-setup` sets it up (`dev/setup_mail.rb`).
- Settings come from `.env.sample`, put local overrides into `.env`.
- The portal calls Triage with `API_TOKEN`. Triage calls the portal on the host at `http://host.docker.internal:3000` (webhooks signed with `WEBHOOK_SECRET`, responsible subject search). The ops-portal `.env.sample` has the same values.

One stack runs with 1.5 GB of Docker Desktop memory, a second Zammad (e.g. a Backoffice) or Elasticsearch needs more (Settings → Resources). When memory runs out, Zammad containers exit with code 137.

To click through together with the portal, follow "Local Triage" in the [ops-portal README](https://github.com/slovensko-digital/ops-portal#local-triage).

## First time deployment

```
# Elasticsearch setup and deploy
kamal accessory boot elastic -d staging
kamal elastic_init_users -d staging
kamal accessory boot kibana -d staging

# Zammad deploy
kamal deploy -d staging
```

## Kamal

Copy `.env` to `.env.staging` file and set the variables.

Other required ENVs:
```
KAMAL_REGISTRY_USERNAME
KAMAL_REGISTRY_PASSWORD
```

E.g. set personal registry secrets in your `~/.bash_profile`:
```
export KAMAL_REGISTRY_PASSWORD=...
export KAMAL_REGISTRY_USERNAME=...
```

## S3 config

Set `S3_URL` env if S3 should be used for storage. Otherwise, database is used by default.
```
S3_URL=https://<access_key_id>:<access_key_secret>@s3.<region>.amazonaws.com/<bucket_name>?region=<region>&force_path_style=true
```

## Add Backoffice to Elasticsearch

```
kamal elastic_add_backoffice -d staging
```

You will be prompted for username and password. The script will then create user `username` with given password, and role `username` with access to `username-index*` indicies.
