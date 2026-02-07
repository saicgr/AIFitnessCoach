# FitWiz Release Keystore

This directory contains the release signing keystore for the FitWiz Android app.

## Files

- `release.keystore` - Release signing key (RSA 2048-bit, validity 10000 days)
- `debug.keystore` - Debug signing key (development only)

## CI/CD Environment Variables

Set the following environment variables in your CI/CD pipeline (GitHub Actions, Codemagic, etc.):

| Variable | Description | Example |
|---|---|---|
| `KEYSTORE_PATH` | Absolute path to the keystore file | `/path/to/release.keystore` |
| `KEYSTORE_PASSWORD` | Password for the keystore | *(set securely)* |
| `KEY_ALIAS` | Alias of the signing key | `fitwiz` |
| `KEY_PASSWORD` | Password for the key alias | *(set securely)* |

## Local Development

For local release builds, create a `key.properties` file in `mobile/flutter/android/` (it is already gitignored):

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=fitwiz
storeFile=../keystores/release.keystore
```

## Security Notes

- NEVER commit keystore files or `key.properties` to version control.
- The `*.keystore`, `*.jks`, and `key.properties` patterns are already in `.gitignore`.
- Store keystore passwords in a secure secrets manager (GitHub Secrets, Codemagic env vars, etc.).
- Back up the keystore securely -- if lost, you cannot update the app on Play Store.
