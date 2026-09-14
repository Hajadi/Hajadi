#!/usr/bin/env python3
"""Generate the bundled sample dataset in assets/sample_data/.

The same JSON files feed two things:
  * demo mode inside the app (DemoDataService reads them from the bundle);
  * `node scripts/seed_firestore.js`, which loads them into a real project.

Run: python3 scripts/generate_sample_data.py
"""
import json
import pathlib
import random
from datetime import datetime, timedelta, timezone

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "sample_data"
OUT.mkdir(parents=True, exist_ok=True)

random.seed(1804)  # Haitian independence — deterministic output.

NOW = datetime(2026, 9, 13, 9, 30, tzinfo=timezone.utc)


def iso(dt: datetime) -> str:
    return dt.replace(microsecond=0).isoformat().replace("+00:00", "Z")


DEPARTMENTS = {
    "ouest": (18.5944, -72.3074, ["Port-au-Prince", "Delmas", "Pétion-Ville", "Carrefour", "Croix-des-Bouquets", "Léogâne"]),
    "nord": (19.7579, -72.2043, ["Cap-Haïtien", "Limbé", "Milot"]),
    "nord_est": (19.6656, -71.8448, ["Fort-Liberté", "Ouanaminthe"]),
    "nord_ouest": (19.9318, -72.8300, ["Port-de-Paix", "Jean-Rabel"]),
    "artibonite": (19.4500, -72.6833, ["Gonaïves", "Saint-Marc", "Dessalines"]),
    "centre": (19.1500, -72.0167, ["Hinche", "Mirebalais"]),
    "sud": (18.1937, -73.7500, ["Les Cayes", "Aquin", "Port-Salut"]),
    "sud_est": (18.2341, -72.5349, ["Jacmel", "Marigot"]),
    "grand_anse": (18.6500, -74.1167, ["Jérémie", "Corail"]),
    "nippes": (18.4461, -73.0906, ["Miragoâne", "Anse-à-Veau"]),
}

CATEGORIES = [
    "electrician", "plumber", "carpenter", "mason", "mechanic",
    "painter", "welder", "cleaner", "tailor", "ac_technician",
    "hair_stylist", "barber", "makeup_artist", "nail_technician",
    "massage_therapist",
]

# Trades nobody has listed yet, typed by the workers themselves. Demo mode
# needs at least one so the "Other" bucket is not an empty promise.
CUSTOM_TRADES = {
    7: ["Fotograf evènman"],
    13: ["Repetitè lekòl"],
    19: ["DJ ak sonorizasyon", "Dekoratè fèt"],
}

HEADLINES = {
    "electrician": ("Installations et pannes électriques", "Enstalasyon ak pàn elektrik", "Wiring, breakers and inverter setups"),
    "plumber": ("Plomberie et réservoirs", "Plonbri ak rezèvwa", "Leaks, tanks and bathroom fittings"),
    "carpenter": ("Menuiserie sur mesure", "Ebenis sou mezi", "Doors, cabinets and roof framing"),
    "mason": ("Maçonnerie et béton", "Mason ak beton", "Blockwork, plaster and concrete slabs"),
    "mechanic": ("Mécanique auto et moto", "Mekanik oto ak moto", "Engine, brakes and roadside repair"),
    "painter": ("Peinture intérieure et extérieure", "Penti anndan ak deyò", "Interior, exterior and waterproofing"),
    "welder": ("Soudure et ferronnerie", "Soude ak feronri", "Gates, grilles and structural welding"),
    "cleaner": ("Nettoyage maison et bureau", "Netwayaj kay ak biwo", "Homes, offices and post-construction"),
    "tailor": ("Couture et retouches", "Kouti ak retouch", "Uniforms, dresses and alterations"),
    "ac_technician": ("Climatisation et froid", "Klimatizasyon ak fredi", "Split units, servicing and gas refill"),
    "hair_stylist": ("Coiffure femmes et hommes", "Kwafi fanm ak gason", "Cuts, braids, locs and treatments"),
    "barber": ("Barbier et taille de barbe", "Barbye ak taye bab", "Fades, line-ups and beard trims"),
    "makeup_artist": ("Maquillage mariage et événements", "Makiyaj maryaj ak evènman", "Bridal, events and photoshoot makeup"),
    "nail_technician": ("Manucure et pédicure", "Maniki ak pedikir", "Gel, acrylics and nail care"),
    "massage_therapist": ("Massage et bien-être", "Masaj ak byennèt", "Deep tissue, relaxation and sports massage"),
}

FIRST = ["Jean", "Marie", "Wilner", "Roseline", "Jacques", "Nadège", "Frantz", "Micheline",
         "Emmanuel", "Guerline", "Ricardo", "Sophonie", "Patrick", "Darline", "Yvon",
         "Mirlande", "Kesner", "Fabiola", "Josué", "Chantal", "Ronald", "Esther",
         "Dieuseul", "Naïka"]
LAST = ["Jean-Baptiste", "Pierre", "Charles", "Désir", "Joseph", "Louis", "Étienne",
        "Saintil", "Dorvil", "Cadet", "Beauvoir", "Alcé", "Fleurival", "Moïse",
        "Toussaint", "Célestin", "Lafontant", "Exantus", "Bazile", "Delva",
        "Augustin", "Noël", "Sainvil", "Pierre-Louis"]


def avatar(seed: str) -> str:
    return f"https://api.dicebear.com/7.x/avataaars/png?seed={seed}&backgroundColor=0A6CFF"


def work_photo(topic: str, n: int) -> str:
    return f"https://images.jwennmet.ht/portfolio/{topic}_{n}.jpg"


def build() -> None:
    users: list[dict] = []
    workers: list[dict] = []

    # --- Fixed demo accounts, documented in the README ------------------
    users.append({
        "id": "demo_customer",
        "fullName": "Marie-Ange Prophète",
        "role": "customer",
        "email": "customer@demo.ht",
        "phone": "+50937120045",
        "photoUrl": avatar("marie-ange"),
        "languageCode": "ht",
        "departmentId": "ouest",
        "city": "Delmas",
        "latitude": 18.5480,
        "longitude": -72.3020,
        "phoneVerified": True,
        "status": "active",
        "favoriteWorkerIds": ["worker_1", "worker_4"],
        "fcmTokens": [],
        "createdAt": iso(NOW - timedelta(days=260)),
    })
    users.append({
        "id": "demo_admin",
        "fullName": "Administratè Jwenn Mèt",
        "role": "admin",
        "email": "admin@demo.ht",
        "phone": "+50928110000",
        "photoUrl": avatar("admin"),
        "languageCode": "fr",
        "departmentId": "ouest",
        "city": "Port-au-Prince",
        "phoneVerified": True,
        "status": "active",
        "favoriteWorkerIds": [],
        "fcmTokens": [],
        "createdAt": iso(NOW - timedelta(days=400)),
    })

    names = [f"{FIRST[i % len(FIRST)]} {LAST[(i * 7) % len(LAST)]}" for i in range(24)]
    dept_ids = list(DEPARTMENTS)

    for i in range(24):
        wid = "demo_worker" if i == 0 else f"worker_{i}"
        dept = dept_ids[i % len(dept_ids)]
        lat, lon, cities = DEPARTMENTS[dept]
        city = cities[i % len(cities)]
        primary = CATEGORIES[i % len(CATEGORIES)]
        extra = CATEGORIES[(i * 3 + 1) % len(CATEGORIES)]
        cats = [primary] if i % 3 else [primary, extra]
        custom = CUSTOM_TRADES.get(i, [])
        if custom:
            cats = cats + ["other"]
        rating = round(random.uniform(3.6, 5.0), 1)
        reviews = random.randint(4, 96)
        verification = "approved" if i % 5 != 4 else ("pending" if i % 2 else "unverified")
        name = "Wilner Dorcéus" if i == 0 else names[i]
        fr, ht, en = HEADLINES[primary]

        users.append({
            "id": wid,
            "fullName": name,
            "role": "worker",
            "email": "worker@demo.ht" if i == 0 else f"{wid}@demo.ht",
            "phone": f"+509{random.randint(30000000, 49999999)}",
            "photoUrl": avatar(wid),
            "languageCode": ["ht", "fr", "en"][i % 3],
            "departmentId": dept,
            "city": city,
            "latitude": round(lat + random.uniform(-0.08, 0.08), 5),
            "longitude": round(lon + random.uniform(-0.08, 0.08), 5),
            "phoneVerified": True,
            "status": "active",
            "favoriteWorkerIds": [],
            "fcmTokens": [],
            "createdAt": iso(NOW - timedelta(days=random.randint(30, 700))),
        })

        workers.append({
            "id": wid,
            "fullName": name,
            "categoryIds": cats,
            "customCategories": custom,
            "departmentId": dept,
            "city": city,
            "headline": {"ht": ht, "fr": fr, "en": en}[["ht", "fr", "en"][i % 3]],
            "bio": (
                f"{name} — {en.lower()}. "
                f"{random.randint(3, 22)} ane eksperyans nan {city} ak zòn nan. "
                "Travay garanti, devi gratis anvan chak travay."
            ),
            "photoUrl": avatar(wid),
            "phone": f"+509{random.randint(30000000, 49999999)}",
            "hourlyRate": float(random.choice([350, 500, 650, 750, 900, 1100, 1400, 1800])),
            "currency": "HTG",
            "rating": rating,
            "reviewCount": reviews,
            "jobsCompleted": reviews + random.randint(0, 40),
            "yearsExperience": random.randint(2, 25),
            "verification": verification,
            "availableNow": i % 3 != 2,
            "serviceDepartmentIds": sorted({dept, dept_ids[(i + 1) % len(dept_ids)]}),
            "serviceCities": cities[:3],
            "portfolio": [
                {
                    "id": f"{wid}_p{n}",
                    "imageUrl": work_photo(primary, n),
                    "caption": ["Travay fini", "Chantye an kou", "Detay fini an"][n - 1],
                    "categoryId": primary,
                    "uploadedAt": iso(NOW - timedelta(days=random.randint(5, 200))),
                }
                for n in range(1, random.randint(2, 4))
            ],
            "certificates": (
                [{
                    "id": f"{wid}_c1",
                    "title": "INFP — Sètifika pwofesyonèl",
                    "fileUrl": f"https://files.jwennmet.ht/certificates/{wid}.pdf",
                    "issuer": "Institut National de Formation Professionnelle",
                    "issuedAt": iso(NOW - timedelta(days=random.randint(400, 2000))),
                }] if verification == "approved" and i % 2 == 0 else []
            ),
            "latitude": round(lat + random.uniform(-0.08, 0.08), 5),
            "longitude": round(lon + random.uniform(-0.08, 0.08), 5),
            "acceptedPaymentMethods": (
                ["moncash", "natcash", "card", "cash"] if i % 4
                else ["moncash", "cash"]
            ),
            "suspended": False,
            "createdAt": iso(NOW - timedelta(days=random.randint(30, 700))),
        })

    # --- Jobs ------------------------------------------------------------
    job_descriptions = [
        "Priz kizin nan pa gen kouran depi yè swa, disjonktè a sote chak fwa.",
        "Fuite anba lavabo saldeben an, dlo ap koule tout lajounen.",
        "Mwen bezwen de pòt an bwa pou chanm yo, ak kad yo.",
        "Mi kloti a fann, li bezwen repare ak yon kouch siman.",
        "Moto a pa vle limen, mwen kwè se demarè a.",
        "Penti salon ak koridò — apeprè 60 mètkare.",
        "Griyaj fenèt yo bezwen soude ankò apre siklòn nan.",
        "Netwayaj apre konstriksyon pou yon apatman de chanm.",
        "Retouch sou dis inifòm lekòl pou timoun yo.",
        "Klimatizè a pa bay fredi, li bezwen gaz ak antretyen.",
    ]
    statuses = ["completed", "completed", "completed", "pending", "accepted",
                "in_progress", "rejected", "completed", "pending", "completed"]
    jobs = []
    invoices = []
    reviews_out = []
    custom_trade_job_done = False

    for i in range(18):
        worker = workers[(i * 5 + 3) % len(workers)]
        customer = users[0] if i % 3 == 0 else {
            "id": f"customer_{i}",
            "fullName": names[(i * 5) % len(names)],
            "photoUrl": avatar(f"customer_{i}"),
        }
        if customer["id"] != "demo_customer" and not any(u["id"] == customer["id"] for u in users):
            users.append({
                "id": customer["id"],
                "fullName": customer["fullName"],
                "role": "customer",
                "email": f"{customer['id']}@demo.ht",
                "phone": f"+509{random.randint(30000000, 49999999)}",
                "photoUrl": customer["photoUrl"],
                "languageCode": ["ht", "fr"][i % 2],
                "departmentId": worker["departmentId"],
                "city": worker["city"],
                "phoneVerified": True,
                "status": "active",
                "favoriteWorkerIds": [],
                "fcmTokens": [],
                "createdAt": iso(NOW - timedelta(days=random.randint(10, 300))),
            })

        status = statuses[i % len(statuses)]
        # One demo job booked against a trade nobody listed, so the "Other"
        # path is walkable end to end and not just a profile decoration.
        use_custom = bool(worker["customCategories"]) and not custom_trade_job_done
        custom_trade_job_done = custom_trade_job_done or use_custom
        created = NOW - timedelta(days=random.randint(1, 90), hours=random.randint(0, 20))
        price = float(random.choice([1500, 2500, 3200, 4500, 6000, 8500, 12000]))
        job_id = f"job_{i + 1}"
        job = {
            "id": job_id,
            "customerId": customer["id"],
            "customerName": customer["fullName"],
            "customerPhotoUrl": customer["photoUrl"],
            "workerId": worker["id"],
            "workerName": worker["fullName"],
            "workerPhotoUrl": worker["photoUrl"],
            "categoryId": "other" if use_custom else worker["categoryIds"][0],
            "customCategory": (
                worker["customCategories"][0] if use_custom else None
            ),
            "description": job_descriptions[i % len(job_descriptions)],
            "status": status,
            "paymentMethod": ["moncash", "natcash", "card", "cash"][i % 4],
            "departmentId": worker["departmentId"],
            "city": worker["city"],
            "addressNote": f"{random.randint(1, 99)}, Ri {random.choice(['Kapwa', 'Lamè', 'Nò', 'Delmas 33', 'Rue Pavée'])}",
            "latitude": worker["latitude"],
            "longitude": worker["longitude"],
            "budget": price,
            "agreedPrice": price if status in ("completed", "in_progress") else None,
            "photoUrls": [],
            "scheduledAt": iso(created + timedelta(days=2)),
            "createdAt": iso(created),
            "updatedAt": iso(created + timedelta(hours=6)),
            "completedAt": iso(created + timedelta(days=3)) if status == "completed" else None,
            "reviewId": f"review_{i + 1}" if status == "completed" else None,
            "invoiceId": f"invoice_{i + 1}" if status == "completed" else None,
        }
        jobs.append(job)

        if status == "completed":
            fee = round(price * 0.10, 2)
            card_receipt = {}
            if job["paymentMethod"] == "card":
                # Only ever the brand and the last four digits — a full card
                # number must never reach Firestore.
                card_receipt = {
                    # Alternate across card invoices so both brands appear.
                    "cardBrand": ["visa", "mastercard"][len(invoices) % 2],
                    "cardLast4": f"{random.randint(1000, 9999)}",
                }
            invoices.append({
                "id": f"invoice_{i + 1}",
                "number": f"JM-2026-{1000 + i}",
                "jobId": job_id,
                "customerId": customer["id"],
                "customerName": customer["fullName"],
                "workerId": worker["id"],
                "workerName": worker["fullName"],
                "subtotal": price,
                "serviceFee": fee,
                "currency": "HTG",
                "method": job["paymentMethod"],
                "status": "paid",
                "transactionRef": f"{job['paymentMethod'].upper()}-{random.randint(100000, 999999)}",
                **card_receipt,
                "issuedAt": iso(created + timedelta(days=3)),
                "paidAt": iso(created + timedelta(days=3, hours=1)),
            })
            comments = [
                "Bon travay, li rive alè epi li kite kay la pwòp.",
                "Travay la byen fèt, pri a te rezonab. Mwen rekòmande.",
                "Profesyonèl et ponctuel, je referai appel à lui.",
                "Very clean work and clear explanation of the problem.",
                "Li pran tan pou l eksplike m tout bagay. Mèsi anpil!",
            ]
            reviews_out.append({
                "id": f"review_{i + 1}",
                "jobId": job_id,
                "workerId": worker["id"],
                "customerId": customer["id"],
                "customerName": customer["fullName"],
                "customerPhotoUrl": customer["photoUrl"],
                "rating": float(random.choice([4, 4.5, 5, 5, 4])),
                "comment": comments[i % len(comments)],
                "status": "published" if i % 7 else "pending",
                "workerReply": "Mèsi pou konfyans ou!" if i % 4 == 0 else None,
                "createdAt": iso(created + timedelta(days=4)),
            })

    # --- Conversations ---------------------------------------------------
    conversations = []
    for i, job in enumerate(jobs[:4]):
        pair = sorted([job["customerId"], job["workerId"]])
        cid = f"{pair[0]}_{pair[1]}"
        base = datetime.fromisoformat(job["createdAt"].replace("Z", "+00:00"))
        thread = [
            (job["customerId"], job["description"]),
            (job["workerId"], "Bonjou! Mwen ka pase demen maten vè 9è. Sa bon pou ou?"),
            (job["customerId"], "Wi sa bon. Konbyen sa ap koute apeprè?"),
            (job["workerId"], f"Apeprè {int(job['budget'])} goud ak materyèl yo. M ap konfime lè m wè l."),
        ]
        conversations.append({
            "id": cid,
            "participantIds": [job["customerId"], job["workerId"]],
            "titles": {job["customerId"]: job["customerName"], job["workerId"]: job["workerName"]},
            "photoUrls": {job["customerId"]: job["customerPhotoUrl"], job["workerId"]: job["workerPhotoUrl"]},
            "jobId": job["id"],
            "lastMessage": thread[-1][1],
            "lastMessageAt": iso(base + timedelta(minutes=40)),
            "unreadCounts": {job["customerId"]: 1 if i == 0 else 0, job["workerId"]: 0},
            "messages": [
                {
                    "id": f"{cid}_m{n}",
                    "senderId": sender,
                    "text": text,
                    "imageUrl": None,
                    "sentAt": iso(base + timedelta(minutes=10 * n)),
                    "readBy": [sender],
                }
                for n, (sender, text) in enumerate(thread, start=1)
            ],
        })

    # --- Notifications ---------------------------------------------------
    notifications = {
        "demo_customer": [
            {"id": "n1", "type": "job_accepted", "messageKey": "notifAccepted",
             "args": {"name": workers[3]["fullName"]}, "jobId": "job_2", "read": False,
             "createdAt": iso(NOW - timedelta(hours=3))},
            {"id": "n2", "type": "message", "messageKey": "notifNewMessage",
             "args": {"name": workers[3]["fullName"]}, "conversationId": conversations[0]["id"],
             "read": False, "createdAt": iso(NOW - timedelta(hours=5))},
            {"id": "n3", "type": "payment", "messageKey": "paymentSuccess", "args": {},
             "jobId": "job_1", "read": True, "createdAt": iso(NOW - timedelta(days=2))},
        ],
        "demo_worker": [
            {"id": "n4", "type": "job_request", "messageKey": "notifNewRequest",
             "args": {"name": "Marie-Ange Prophète"}, "jobId": "job_4", "read": False,
             "createdAt": iso(NOW - timedelta(hours=1))},
            {"id": "n5", "type": "review", "messageKey": "notifReviewReceived",
             "args": {"name": "Marie-Ange Prophète"}, "read": True,
             "createdAt": iso(NOW - timedelta(days=4))},
            {"id": "n6", "type": "verification", "messageKey": "notifVerified",
             "args": {}, "read": True, "createdAt": iso(NOW - timedelta(days=30))},
        ],
    }

    # --- Verification queue & reports ------------------------------------
    verification_requests = [
        {
            "id": w["id"],
            "workerName": w["fullName"],
            "idDocumentUrl": f"https://files.jwennmet.ht/id/{w['id']}.jpg",
            "idType": "cin",
            "certificateUrls": [],
            "status": "pending",
            "submittedAt": iso(NOW - timedelta(days=idx + 1)),
        }
        for idx, w in enumerate(workers) if w["verification"] == "pending"
    ]

    reports = [
        {
            "id": "report_1",
            "reporterId": "demo_customer",
            "targetUserId": workers[6]["id"],
            "targetName": workers[6]["fullName"],
            "reason": "fraud",
            "details": "Li mande depo avan epi li pa janm vini.",
            "jobId": "job_7",
            "status": "open",
            "createdAt": iso(NOW - timedelta(days=1)),
        },
        {
            "id": "report_2",
            "reporterId": workers[2]["id"],
            "targetUserId": "customer_4",
            "targetName": "Kliyan an",
            "reason": "abuse",
            "details": "Mesaj ki pa respektan nan chat la.",
            "status": "open",
            "createdAt": iso(NOW - timedelta(days=6)),
        },
    ]

    files = {
        "users.json": users,
        "workers.json": workers,
        "jobs.json": jobs,
        "reviews.json": reviews_out,
        "conversations.json": conversations,
        "notifications.json": notifications,
        "invoices.json": invoices,
        "verification_requests.json": verification_requests,
        "reports.json": reports,
    }
    for name, payload in files.items():
        (OUT / name).write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        size = len(payload)
        print(f"{name}: {size} records")


if __name__ == "__main__":
    build()
