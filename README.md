# OPS Triage Zammad

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
