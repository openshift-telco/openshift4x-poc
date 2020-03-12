#!/bin/env python3

try:
    import bcrypt, base64
except ImportError:
    raise ImportError("Missing 'bcrypt' or 'base64' libraries ")

# Password Format: 5char-5char-5char-5char
MYPASSWORD = b"a1b2c-3d4e5-f6g7h-8i9ab"

# Generate ascii encoded encrypted password with random salt
encrypted_password = bcrypt.hashpw(MYPASSWORD,bcrypt.gensalt())

b64_password = base64.b64encode(encrypted_password)

print ("OCP base64 encoded password:",b64_password)