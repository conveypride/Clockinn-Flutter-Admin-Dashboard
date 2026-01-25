# clockinn_flutter_admin

A new Flutter project.

## Getting Started

<!--=== ALWAYS REMEMEBER TO INJECT THE GOOGLE MAP API KEY WHEN RUNNING OR DEPLOYING THIS APP LIKE THIS === -->
<!-- FOR TESTING -->
flutter run -d chrome --dart-define=MAPS_API_KEY=AIzaSyB87_uR_youkey --web-port=54254
<!-- FOR PRODUCTION -->
flutter build web --dart-define=MAPS_API_KEY=AIzaSyB...YourKey
 <!--===END OF  ALWAYS REMEMEBER TO INJECT THE GOOGLE MAP API KEY WHEN RUNNING OR DEPLOYING THIS APP LIKE THIS === -->


<!-- DATA STRUCTURE -->
ROOT
│
├── 📂 adminusers (Collection)
│   └── 📄 {userId} (Document)
│       ├── admincontact: "0207271638"
│       ├── adminname: "AWC English Assembly"
│       ├── companyId: "awceRX3kQI4H"
│       ├── companyname: "AWC English Assembly"
│       ├── datejoined: Timestamp
│       ├── email: "awcpentecost@gmail.com"
│       ├── isSuperAdmin: true
│       ├── status: true
│       └── uid: "44dKAAvWy6MXuBHe..."
│
├── 📂 allusers (Collection)
│   └── 📄 {userId} (Document)
│       ├── companyId: "lgmgpHEWCpbn"
│       ├── email: "lgmguser@gmail.com"
│       ├── isActive: true
│       ├── siteId: "lgmgqWqBaHTS"
│       ├── token: "etvcuUUiQDC6..."
│       └── uid: "BYKbpOUyrCgf..."
│
├── 📂 companies (Collection)
│   └── 📄 {companyId} (Document)
│       ├── amount: "1500"
│       ├── billing_cycle: "yearly"
│       ├── companySize: 3
│       ├── companyscription: "active"
│       ├── countOperationSites: 1
│       ├── department: ["none", "LGMG ACCRA OFFICE"]
│       ├── locationVerificationEnabled: true
│       ├── name: "LGMG"
│       └── requireBothVerifications: false
│
├── 📂 operationSites (Collection)
│   └── 📂 {companyId} (Sub-collection)
│       └── 📂 sites (Sub-collection)
│           └── 📄 {siteId} (Document)
│               ├── openingTime: "08:30"
│               ├── closingTime: "02:00"
│               ├── holidaylist: [{"May Day": "2025-05-01"}]
│               ├── lat / lng: "5.6963" / "-0.2166"
│               ├── nameofsite: "LGMG ACCRA OFFICE"
│               ├── radius: 100
│               └── workingdays: ["mon", "tue", "wed", "thu", "fri", "sat"]
│
├── 📂 users (Collection)
│   └── 📂 {companyId} (Sub-collection)
│       └── 📂 sites (Sub-collection)
│           └── 📂 {siteId} (Sub-collection)
│               └── 📂 users (Sub-collection)
│                   └── 📄 {userId} (Document)
│                       ├── name: "lgmg Best user"
│                       ├── role: "Employee"
│                       ├── picurl: "https://firebasestorage..."
│                       ├── department: "LGMG ACCRA OFFICE"
│                       └── 📂 devices (Sub-collection)
│                           └── 📄 {deviceId} (Document)
│                               ├── devicename: "TECNO KJ5"
│                               └── status: true
│
├── 📂 attendance (Collection)
│   └── 📂 {companyId} (Sub-collection)
│       └── 📂 sites (Sub-collection)
│           └── 📂 {siteId} (Sub-collection)
│               └── 📂 users (Sub-collection)
│                   └── 📂 {userId} (Sub-collection)
│                       └── 📂 records (Sub-collection)
│                           └── 📄 {recordId} (Document)
│                               ├── checkInTime: Timestamp
│                               ├── checkOutTime: Timestamp
│                               ├── date: Timestamp (00:00:00)
│                               ├── status: "done"
│                               └── workingHours: "12:14"
│
└── 📂 timetable (Collection)
    └── 📂 {companyId} (Sub-collection)
        └── 📂 users (Sub-collection)
            └── 📂 {userId} (Sub-collection)
                └── 📂 schedulerData (Sub-collection)
                    └── 📄 {scheduleId} (Document)
                        ├── text: "sally and theo"
                        ├── startDate: Timestamp
                        ├── endDate: Timestamp
                        └── recurrenceRule: "FREQ=DAILY;..."