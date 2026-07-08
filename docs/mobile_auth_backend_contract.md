# Friends Bingo mobile auth contract

This repository now expects the backend to support persistent mobile auth with rotating refresh sessions.

## Required token model

- `accessToken`: JWT or equivalent bearer token with a 15 minute lifetime.
- `refreshToken`: opaque long-lived token with a 90 day lifetime.
- Refresh tokens are stored server-side as hashed session records.

## Required refresh session table

Each active device session should store:

- `userId`
- `deviceId`
- `refreshTokenHash`
- `expiresAt`
- `revokedAt`
- `lastUsedAt`

## Endpoint contract

### `POST /auth/login`

Request body:

```json
{
  "phoneNumber": "0912345678",
  "password": "secret",
  "deviceId": "install-uuid"
}
```

Success response envelope data:

```json
{
  "accessToken": "short-lived-token",
  "refreshToken": "long-lived-token",
  "user": {
    "...": "current user profile"
  }
}
```

### `POST /auth/refresh`

Request body:

```json
{
  "refreshToken": "current-refresh-token",
  "deviceId": "install-uuid"
}
```

Behavior:

- Validate the refresh session for the given device.
- Reject expired or revoked sessions.
- Rotate the refresh token every time.
- Revoke the previous refresh token as part of the same transaction.
- Update `lastUsedAt`.

Success response envelope data:

```json
{
  "accessToken": "new-short-lived-token",
  "refreshToken": "new-long-lived-token",
  "user": {
    "...": "current user profile"
  }
}
```

The `user` object is preferred. If omitted, the Flutter client will call `GET /auth/me` with the new access token.

### `POST /auth/logout`

Request body:

```json
{
  "refreshToken": "current-refresh-token",
  "deviceId": "install-uuid"
}
```

Behavior:

- Revoke only the current device session.
- Return success even if the client access token is already expired.

### `GET /auth/me`

Behavior:

- Return the authenticated user profile for the current access token.

## Revocation rules

- Password change must revoke every refresh session for the user.
- Manual logout must revoke only the current device session.
- Refresh failure for expired or revoked sessions should return an auth error so the client can send the user back to login.
