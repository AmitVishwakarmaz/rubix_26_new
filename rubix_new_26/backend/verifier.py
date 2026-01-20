"""
E-ID Credential Verifier - Verifies JWT from QR code.
"""

import jwt
from PIL import Image
from pyzbar.pyzbar import decode
import os
import base64
from io import BytesIO

from common import public_pem, revoked_ids


def verify_eid_credential(token):
    """
    Verify an E-ID JWT credential.
    Returns (success, message, decoded_data)
    """
    try:
        decoded = jwt.decode(token, public_pem, algorithms=["RS256"])
        eid = decoded.get("sub")
        
        # Check revocation
        if eid in revoked_ids:
            return False, f"❌ Credential revoked for {decoded.get('name')}", None
        
        # Valid credential
        return True, f"✅ Verified: {decoded.get('name')}", decoded
    
    except jwt.ExpiredSignatureError:
        return False, "❌ Credential expired", None
    except jwt.InvalidTokenError as e:
        return False, f"❌ Invalid credential: {str(e)}", None


def read_qr_from_image(image_path):
    """Read JWT from QR code image file."""
    try:
        img = Image.open(image_path)
        decoded_objs = decode(img)
        
        if not decoded_objs:
            return None, "No QR code found in image"
        
        jwt_token = decoded_objs[0].data.decode('utf-8')
        return jwt_token, None
    
    except Exception as e:
        return None, f"Error reading QR: {str(e)}"


def read_qr_from_base64(base64_string):
    """Read JWT from base64-encoded QR image."""
    try:
        image_data = base64.b64decode(base64_string)
        img = Image.open(BytesIO(image_data))
        decoded_objs = decode(img)
        
        if not decoded_objs:
            return None, "No QR code found in image"
        
        jwt_token = decoded_objs[0].data.decode('utf-8')
        return jwt_token, None
    
    except Exception as e:
        return None, f"Error reading QR: {str(e)}"


def verify_qr_image(image_path):
    """Read QR from image and verify the JWT."""
    jwt_token, error = read_qr_from_image(image_path)
    if error:
        return False, error, None
    
    return verify_eid_credential(jwt_token)


def verify_qr_base64(base64_string):
    """Read QR from base64 image and verify the JWT."""
    jwt_token, error = read_qr_from_base64(base64_string)
    if error:
        return False, error, None
    
    return verify_eid_credential(jwt_token)


if __name__ == "__main__":
    # Test with image
    qr_path = input("Enter path to QR code image: ").strip()
    
    if not os.path.exists(qr_path):
        print("File not found!")
    else:
        success, message, data = verify_qr_image(qr_path)
        print(f"\nVerification Result: {message}")
        
        if success and data:
            print("\nDecoded Data:")
            for key, value in data.items():
                print(f"  {key}: {value}")
