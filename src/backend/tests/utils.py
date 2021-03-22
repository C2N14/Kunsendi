def token_to_header(token) -> dict:
    return {'Authorization': f'Bearer {token}'}
