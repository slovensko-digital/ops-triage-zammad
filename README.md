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

Required key files:
```
config/
  master.key
  postgresql.key
```

TODO: Read staging and prod secrets from a shared secret repository!
