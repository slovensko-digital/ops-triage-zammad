# OPS Triage Zammad

## First time deployment

```
kamal build push -d staging
kamal accessory boot -d staging all
kamal zammad_init -d staging
kamal deploy -d staging
```

## Kamal

Required ENVs:
```
KAMAL_REGISTRY_USERNAME
KAMAL_REGISTRY_PASSWORD
```

E.g. set personal registry secrets in your `~/.bash_profile`:
```
export KAMAL_REGISTRY_PASSWORD=...
export KAMAL_REGISTRY_USERNAME=...
```

Also copy `.env` to `.env.staging` file and set the variables:
```
RAILS_MASTER_KEY=
POSTGRES_PASSWORD=
```
