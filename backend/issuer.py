"""
E-ID Credential Issuer - Creates JWT-based E-ID with QR code.
"""

import jwt
import datetime
import qrcode
import base64
from io import BytesIO
import os

from common import private_key, revoked_ids

QR_DIR = os.path.join(os.path.dirname(__file__), "qr_codes")
os.makedirs(QR_DIR, exist_ok=True)


def issue_eid_credential(eid, user_id, name, email, role, university_id, entered_id, valid_days=365):
    """
    Issue an E-ID credential as a signed JWT.
    """
    payload = {
        "sub": eid,
        "user_id": user_id,
        "name": name,
        "email": email,
        "role": role,
        "university_id": university_id,
        "entered_id": entered_id,
        "type": "university_eid",
        "iat": datetime.datetime.utcnow(),
        "exp": datetime.datetime.utcnow() + datetime.timedelta(days=valid_days)
    }
    
    token = jwt.encode(payload, private_key, algorithm="RS256")
    print(f"[Issuer] Created E-ID credential: {eid}")
    return token


def generate_qr_code(jwt_token, eid):
    """
    Generate QR code from JWT and save to file.
    Returns the file path.
    """
    img = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    img.add_data(jwt_token)
    img.make(fit=True)
    
    qr_img = img.make_image(fill_color="black", back_color="white")
    
    filepath = os.path.join(QR_DIR, f"{eid}.png")
    qr_img.save(filepath)
    
    print(f"[Issuer] QR code saved: {filepath}")
    return filepath


def get_qr_base64(filepath):
    """Convert QR image to base64 string."""
    if not os.path.exists(filepath):
        return ""
    
    with open(filepath, "rb") as f:
        return base64.b64encode(f.read()).decode('utf-8')


def generate_qr_base64_direct(jwt_token):
    """Generate QR code and return as base64 directly."""
    img = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    img.add_data(jwt_token)
    img.make(fit=True)
    
    qr_img = img.make_image(fill_color="black", back_color="white")
    
    buffer = BytesIO()
    qr_img.save(buffer, format="PNG")
    buffer.seek(0)
    
    return base64.b64encode(buffer.getvalue()).decode('utf-8')


def revoke_eid(eid):
    """Revoke an E-ID credential."""
    revoked_ids.add(eid)
    print(f"[Issuer] Revoked E-ID: {eid}")


if __name__ == "__main__":
    # Test
    eid = "EID-TEST001"
    token = issue_eid_credential(
        eid=eid,
        user_id="user123",
        name="Amit Vishwakarma",
        email="amit@example.com",
        role="student",
        university_id="uni_001",
        entered_id="IITD2023001"
    )
    
    print(f"\nJWT Token:\n{token[:100]}...")
    
    qr_path = generate_qr_code(token, eid)
    print(f"\nQR Code saved at: {qr_path}")
