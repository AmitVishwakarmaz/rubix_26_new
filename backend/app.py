"""
Flask Server for University E-ID Verification System.
JWT-based QR code workflow with admin verification.
"""

import os
import uuid
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from datetime import datetime, timezone

from common import JWKS, revoked_ids
from issuer import issue_eid_credential, generate_qr_code, get_qr_base64, generate_qr_base64_direct, revoke_eid
from verifier import verify_eid_credential, verify_qr_base64
from firebase_config import (
    get_universities,
    check_student_id,
    check_alumni_id,
    save_verification_request,
    get_verification_request,
    update_verification_request,
    get_pending_requests,
    update_user_verification_status,
    FIREBASE_ENABLED
)

app = Flask(__name__)
CORS(app)

QR_DIR = os.path.join(os.path.dirname(__file__), "qr_codes")
os.makedirs(QR_DIR, exist_ok=True)


def generate_eid():
    """Generate unique E-ID."""
    return f"EID-{uuid.uuid4().hex[:8].upper()}"


@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "ok",
        "service": "University E-ID Verification System",
        "mode": "firebase" if FIREBASE_ENABLED else "local_simulation"
    })


@app.route('/api/jwks', methods=['GET'])
def get_jwks():
    """Get JSON Web Key Set for JWT verification."""
    return jsonify(JWKS)


@app.route('/api/universities', methods=['GET'])
def list_universities():
    universities = get_universities()
    return jsonify({"success": True, "universities": universities})


@app.route('/api/register', methods=['POST'])
def register_for_eid():
    """
    User registers for E-ID.
    Creates JWT credential + QR code.
    """
    data = request.get_json()
    
    required = ['userId', 'name', 'universityId', 'role', 'enteredId']
    for field in required:
        if not data.get(field):
            return jsonify({"success": False, "error": f"Missing: {field}"}), 400
    
    user_id = data['userId']
    name = data['name']
    email = data.get('email', '')
    role = data['role'].lower()
    university_id = data['universityId']
    entered_id = data['enteredId']
    
    # Check if ID matches university records
    if role == 'student':
        matched, matched_data = check_student_id(university_id, entered_id)
    else:
        matched, matched_data = check_alumni_id(university_id, entered_id)
    
    # Generate E-ID
    eid = generate_eid()
    
    # Create JWT credential
    jwt_token = issue_eid_credential(
        eid=eid,
        user_id=user_id,
        name=name,
        email=email,
        role=role,
        university_id=university_id,
        entered_id=entered_id
    )
    
    # Generate QR code
    qr_path = generate_qr_code(jwt_token, eid)
    qr_base64 = get_qr_base64(qr_path)
    
    # Save request data
    request_data = {
        "eid": eid,
        "userId": user_id,
        "name": name,
        "email": email,
        "universityId": university_id,
        "role": role,
        "enteredId": entered_id,
        "autoMatched": matched,
        "matchedData": matched_data,
        "jwtToken": jwt_token,
        "qrPath": qr_path,
        "status": "pending",
        "createdAt": datetime.now(timezone.utc).isoformat()
    }
    
    save_verification_request(eid, request_data)
    
    return jsonify({
        "success": True,
        "message": "E-ID created successfully!",
        "eid": eid,
        "autoMatched": matched,
        "matchedData": matched_data,
        "qr_base64": qr_base64,
        "jwt_token": jwt_token,
        "status": "pending"
    })


@app.route('/api/my-eid/<user_id>', methods=['GET'])
def get_my_eid(user_id):
    """Get user's E-ID with QR code."""
    from firebase_config import get_all_eids
    all_eids = get_all_eids()
    
    user_eid = None
    for eid, data in all_eids.items():
        if data.get('userId') == user_id:
            user_eid = data
            break
    
    if not user_eid:
        return jsonify({"success": False, "error": "No E-ID found"}), 404
    
    qr_base64 = ""
    if user_eid.get('qrPath') and os.path.exists(user_eid['qrPath']):
        qr_base64 = get_qr_base64(user_eid['qrPath'])
    
    return jsonify({
        "success": True,
        "eid": user_eid.get('eid'),
        "name": user_eid.get('name'),
        "email": user_eid.get('email'),
        "role": user_eid.get('role'),
        "universityId": user_eid.get('universityId'),
        "enteredId": user_eid.get('enteredId'),
        "status": user_eid.get('status'),
        "autoMatched": user_eid.get('autoMatched'),
        "qr_base64": qr_base64,
        "jwt_token": user_eid.get('jwtToken')
    })


@app.route('/api/pending', methods=['GET'])
def get_pending():
    """Admin: Get all pending E-ID requests."""
    pending = get_pending_requests()
    
    result = []
    for req in pending:
        result.append({
            "eid": req.get('eid'),
            "userId": req.get('userId'),
            "name": req.get('name'),
            "email": req.get('email'),
            "role": req.get('role'),
            "universityId": req.get('universityId'),
            "enteredId": req.get('enteredId'),
            "autoMatched": req.get('autoMatched'),
            "matchedData": req.get('matchedData'),
            "createdAt": req.get('createdAt')
        })
    
    return jsonify({"success": True, "count": len(result), "requests": result})


@app.route('/api/verify-qr', methods=['POST'])
def verify_qr():
    """
    Admin: Verify a QR code (JWT token).
    Body: { jwt_token } OR { qr_base64 }
    """
    data = request.get_json()
    
    jwt_token = data.get('jwt_token')
    qr_base64 = data.get('qr_base64')
    
    if qr_base64:
        # Verify from QR image
        success, message, decoded = verify_qr_base64(qr_base64)
    elif jwt_token:
        # Verify JWT directly
        success, message, decoded = verify_eid_credential(jwt_token)
    else:
        return jsonify({"success": False, "error": "Provide jwt_token or qr_base64"}), 400
    
    if not success:
        return jsonify({
            "success": False,
            "verified": False,
            "message": message
        })
    
    # Get stored data
    eid = decoded.get('sub')
    stored_data = get_verification_request(eid)
    
    return jsonify({
        "success": True,
        "verified": True,
        "message": message,
        "eid": eid,
        "data": {
            "userId": decoded.get('user_id'),
            "name": decoded.get('name'),
            "email": decoded.get('email'),
            "role": decoded.get('role'),
            "universityId": decoded.get('university_id'),
            "enteredId": decoded.get('entered_id'),
            "autoMatched": stored_data.get('autoMatched') if stored_data else None,
            "matchedData": stored_data.get('matchedData') if stored_data else None,
            "status": stored_data.get('status') if stored_data else 'unknown'
        }
    })


@app.route('/api/approve/<eid>', methods=['POST'])
def approve_eid(eid):
    """Admin: Approve an E-ID after verification."""
    eid_data = get_verification_request(eid)
    if not eid_data:
        return jsonify({"success": False, "error": "E-ID not found"}), 404
    
    update_verification_request(eid, {
        "status": "approved",
        "approvedAt": datetime.now(timezone.utc).isoformat()
    })
    
    # Update user status
    update_user_verification_status(eid_data['userId'], 'verified')
    
    return jsonify({
        "success": True,
        "message": f"✅ E-ID {eid} approved!",
        "name": eid_data.get('name')
    })


@app.route('/api/reject/<eid>', methods=['POST'])
def reject_eid(eid):
    """Admin: Reject an E-ID."""
    data = request.get_json() or {}
    reason = data.get('reason', '')
    
    eid_data = get_verification_request(eid)
    if not eid_data:
        return jsonify({"success": False, "error": "E-ID not found"}), 404
    
    update_verification_request(eid, {
        "status": "rejected",
        "rejectionReason": reason,
        "rejectedAt": datetime.now(timezone.utc).isoformat()
    })
    
    # Update user status
    update_user_verification_status(eid_data['userId'], 'rejected')
    
    # Revoke the JWT
    revoke_eid(eid)
    
    return jsonify({
        "success": True,
        "message": f"❌ E-ID {eid} rejected",
        "name": eid_data.get('name')
    })


@app.route('/api/status/<eid>', methods=['GET'])
def get_eid_status(eid):
    """Get status of an E-ID."""
    eid_data = get_verification_request(eid)
    if not eid_data:
        return jsonify({"success": False, "status": "not_found"})
    
    return jsonify({
        "success": True,
        "eid": eid,
        "status": eid_data.get('status'),
        "name": eid_data.get('name')
    })


@app.route('/api/qr-image/<eid>', methods=['GET'])
def get_qr_image(eid):
    """Download QR image for an E-ID."""
    eid_data = get_verification_request(eid)
    if not eid_data:
        return jsonify({"success": False, "error": "Not found"}), 404
    
    qr_path = eid_data.get('qrPath')
    if not qr_path or not os.path.exists(qr_path):
        return jsonify({"success": False, "error": "QR not found"}), 404
    
    return send_file(qr_path, mimetype='image/png')


if __name__ == '__main__':
    print("=" * 60)
    print("🎓 University E-ID Verification System (JWT-Based)")
    print("=" * 60)
    print(f"\nMode: {'Firebase' if FIREBASE_ENABLED else 'Local Simulation'}")
    print("\nEndpoints:")
    print("  POST /api/register         - Create E-ID + JWT + QR")
    print("  GET  /api/my-eid/<userId>  - Get user's E-ID + QR")
    print("  GET  /api/pending          - Admin: pending requests")
    print("  POST /api/verify-qr        - Admin: verify JWT/QR")
    print("  POST /api/approve/<eid>    - Admin: approve")
    print("  POST /api/reject/<eid>     - Admin: reject")
    print("  GET  /api/jwks             - Public keys for verification")
    print("\nServer: http://localhost:5000")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5000, debug=True)
