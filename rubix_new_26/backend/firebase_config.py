"""
Firebase/Firestore Configuration for University Verification System.
Includes 10 demo data entries for testing.
"""

import os

# Check if Firebase is available
FIREBASE_ENABLED = False
db = None

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    
    SERVICE_ACCOUNT_PATH = os.environ.get(
        'FIREBASE_SERVICE_ACCOUNT',
        os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
    )
    
    if os.path.exists(SERVICE_ACCOUNT_PATH):
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        FIREBASE_ENABLED = True
        print("[Firebase] Connected to Firestore")
    else:
        print("[Firebase] Service account not found, using local simulation")
except ImportError:
    print("[Firebase] firebase-admin not installed, using local simulation")
except Exception as e:
    print(f"[Firebase] Error: {e}, using local simulation")


# ============================================================
# LOCAL SIMULATION DATA - 10 Demo Entries
# ============================================================

LOCAL_UNIVERSITIES = {
    "uni_001": {
        "name": "IIT Delhi",
        "student_ids": {
            "IITD2023001": {
                "studentId": "IITD2023001",
                "name": "Amit Vishwakarma",
                "department": "Computer Science",
                "year": "3rd Year"
            },
            "IITD2023002": {
                "studentId": "IITD2023002",
                "name": "Priya Sharma",
                "department": "Electronics",
                "year": "2nd Year"
            },
            "IITD2022003": {
                "studentId": "IITD2022003",
                "name": "Rahul Verma",
                "department": "Mechanical",
                "year": "4th Year"
            }
        },
        "alumni_ids": {
            "IITDALUM001": {
                "alumniId": "IITDALUM001",
                "name": "Krishna Kumar",
                "graduationYear": 2022,
                "department": "Computer Science"
            },
            "IITDALUM002": {
                "alumniId": "IITDALUM002",
                "name": "Neha Gupta",
                "graduationYear": 2021,
                "department": "Information Technology"
            }
        }
    },
    "uni_002": {
        "name": "IIT Bombay",
        "student_ids": {
            "IITB2023001": {
                "studentId": "IITB2023001",
                "name": "Vikram Patel",
                "department": "Computer Science",
                "year": "3rd Year"
            },
            "IITB2023002": {
                "studentId": "IITB2023002",
                "name": "Sneha Reddy",
                "department": "Civil Engineering",
                "year": "2nd Year"
            }
        },
        "alumni_ids": {
            "IITBALUM001": {
                "alumniId": "IITBALUM001",
                "name": "Anjali Menon",
                "graduationYear": 2020,
                "department": "Electrical Engineering"
            }
        }
    },
    "uni_003": {
        "name": "NIT Trichy",
        "student_ids": {
            "NITT2023001": {
                "studentId": "NITT2023001",
                "name": "Karthik Rajan",
                "department": "Electronics",
                "year": "3rd Year"
            }
        },
        "alumni_ids": {
            "NITTALUM001": {
                "alumniId": "NITTALUM001",
                "name": "Divya Krishnan",
                "graduationYear": 2019,
                "department": "Computer Science"
            }
        }
    }
}

# Local storage
LOCAL_VERIFICATION_REQUESTS = {}
LOCAL_USERS = {}


def get_universities():
    """Get list of all universities."""
    if FIREBASE_ENABLED:
        docs = db.collection('universities').stream()
        return [{"id": doc.id, **doc.to_dict()} for doc in docs]
    return [{"id": k, "name": v["name"]} for k, v in LOCAL_UNIVERSITIES.items()]


def check_student_id(university_id, student_id):
    """Check if student ID exists. Returns (exists, data)."""
    if FIREBASE_ENABLED:
        doc = db.collection('universities').document(university_id)\
                .collection('student_ids').document(student_id).get()
        return (True, doc.to_dict()) if doc.exists else (False, None)
    uni = LOCAL_UNIVERSITIES.get(university_id, {})
    data = uni.get("student_ids", {}).get(student_id)
    return (True, data) if data else (False, None)


def check_alumni_id(university_id, alumni_id):
    """Check if alumni ID exists. Returns (exists, data)."""
    if FIREBASE_ENABLED:
        doc = db.collection('universities').document(university_id)\
                .collection('alumni_ids').document(alumni_id).get()
        return (True, doc.to_dict()) if doc.exists else (False, None)
    uni = LOCAL_UNIVERSITIES.get(university_id, {})
    data = uni.get("alumni_ids", {}).get(alumni_id)
    return (True, data) if data else (False, None)


def save_verification_request(request_id, data):
    """Save verification request."""
    if FIREBASE_ENABLED:
        db.collection('verification_requests').document(request_id).set(data)
    else:
        LOCAL_VERIFICATION_REQUESTS[request_id] = data


def get_verification_request(request_id):
    """Get verification request by ID."""
    if FIREBASE_ENABLED:
        doc = db.collection('verification_requests').document(request_id).get()
        return doc.to_dict() if doc.exists else None
    return LOCAL_VERIFICATION_REQUESTS.get(request_id)


def update_verification_request(request_id, updates):
    """Update verification request."""
    if FIREBASE_ENABLED:
        db.collection('verification_requests').document(request_id).update(updates)
    elif request_id in LOCAL_VERIFICATION_REQUESTS:
        LOCAL_VERIFICATION_REQUESTS[request_id].update(updates)


def get_pending_requests(university_id=None):
    """Get pending verification requests."""
    if FIREBASE_ENABLED:
        query = db.collection('verification_requests').where('adminDecision', '==', 'pending')
        if university_id:
            query = query.where('universityId', '==', university_id)
        return [{"id": doc.id, **doc.to_dict()} for doc in query.stream()]
    results = []
    for req_id, req in LOCAL_VERIFICATION_REQUESTS.items():
        if req.get('adminDecision') == 'pending':
            if university_id is None or req.get('universityId') == university_id:
                results.append({"id": req_id, **req})
    return results


def update_user_verification_status(user_id, status, university_id=None):
    """Update user verification status."""
    if FIREBASE_ENABLED:
        updates = {'verificationStatus': status}
        if university_id:
            updates['universityId'] = university_id
        db.collection('users').document(user_id).update(updates)
    else:
        if user_id not in LOCAL_USERS:
            LOCAL_USERS[user_id] = {}
        LOCAL_USERS[user_id]['verificationStatus'] = status
        if university_id:
            LOCAL_USERS[user_id]['universityId'] = university_id


def get_user(user_id):
    """Get user by ID."""
    if FIREBASE_ENABLED:
        doc = db.collection('users').document(user_id).get()
        return doc.to_dict() if doc.exists else None
    return LOCAL_USERS.get(user_id)


def get_all_eids():
    """Get all E-ID records."""
    if FIREBASE_ENABLED:
        docs = db.collection('verification_requests').stream()
        return {doc.id: doc.to_dict() for doc in docs}
    return LOCAL_VERIFICATION_REQUESTS.copy()


# Print demo data summary on import
print(f"[Data] Loaded {sum(len(u['student_ids']) for u in LOCAL_UNIVERSITIES.values())} students, "
      f"{sum(len(u['alumni_ids']) for u in LOCAL_UNIVERSITIES.values())} alumni across "
      f"{len(LOCAL_UNIVERSITIES)} universities")
