# Fix-Hub: Sequence Diagrams View

This document contains the core sequence diagrams for the Fix-Hub system, rendered using Mermaid.

---

## 1. End-to-End Booking Lifecycle
This diagram tracks a service request from the initial customer booking through technician execution and finally cashier payment.

```mermaid
---
id: 52374dba-bb90-4503-ac9b-cf8034782bf0
---
sequenceDiagram
    participant C as Customer
    participant App as Booking Service
    participant FS as Firestore
    participant T as Technician
    participant Cash as Cashier

    Note over C,FS: Phase 1: Booking Creation
    C->>App: Create Booking (CarId, ServiceId, DateTime)
    App->>FS: Check Slot Availability
    FS-->>App: Slot Available
    App->>FS: addDoc('bookings', status: 'pending')
    FS-->>App: Booking Created (bookingId)
    App->>FS: addDoc('user_notifications') for All Technicians
    FS-->>C: Booking Confirmation
    FS-->>T: Real-time Update: New Job Available

    Note over T,FS: Phase 2: Technician Picks Job
    T->>App: Clicks 'Start Job'
    App->>FS: updateDoc('bookings', {status: 'inProgress', assignedTechnicians: [techId], startedAt: now})
    FS-->>C: Push Notification: Technician Started

    Note over T,FS: Phase 3: Service Execution
    T->>App: Add Service Items
    App->>FS: Update serviceItems[] array
    T->>App: Use Inventory Parts
    App->>FS: Create inventory_transaction (type: 'out')
    App->>FS: Update inventory currentStock
    T->>App: Complete Job
    App->>FS: updateDoc('bookings', {status: 'completedPendingPayment', completedAt: now})
    FS-->>Cash: Notification: Payment Pending
    FS-->>C: Notification: Service Complete

    Note over Cash,FS: Phase 4: Payment Processing
    Cash->>FS: getDoc('bookings', bookingId)
    FS-->>Cash: Return Booking with calculated totalCost
    Cash->>App: Process Payment (method, amount)
    App->>FS: updateDoc('bookings', {isPaid: true, paidAt: now, cashierId, paymentMethod})
    App->>FS: addDoc('invoices', {bookingId, totalAmount, items})
    FS-->>Cash: Invoice Created
    FS-->>C: Notification: Payment Successful + Invoice
```

---

## 2. Registration with Invite Code Validation
Details the security check performed when a Technician or Admin registers.

```mermaid
---
id: a558343c-b8fe-4e35-a500-18bb324353df
---
sequenceDiagram
    participant U as User
    participant App as Registration Form
    participant Valid as Validation Service
    participant FS as Firestore
    participant Auth as Firebase Auth
    participant Notify as Notification Service

    U->>App: Fill Registration Form
    U->>App: Select Role (Tech/Admin)
    App-->>U: Show Invite Code Field
    U->>App: Enter Invite Code
    
    App->>FS: Query inviteCodes where code == inputCode
    FS-->>App: Return Invite Code Document
    
    alt Code Valid
        App->>Auth: createUserWithEmailAndPassword()
        Auth-->>App: Return UID
        App->>FS: Create 'users' Profile
        App->>FS: Update inviteCode: usedCount++
        App-->>U: Registration Success
    else Code Invalid
        App-->>U: Error: Invalid or Expired Code
    end
```

---

## 3. Inventory Management & Stock Alerts
How the system handles parts usage and notifies admins when stock is low.

```mermaid
sequenceDiagram
    participant T as Technician
    participant App as Inventory Service
    participant FS as Firestore
    participant Alert as Alert System
    participant A as Admin

    T->>App: Use Part for Booking
    App->>FS: subtract quantity from 'inventory'
    App->>FS: addDoc('inventory_transactions', {type: 'out'})
    
    FS->>Alert: Trigger: currentStock < threshold
    Alert->>FS: addDoc('low_stock_alerts')
    Alert->>FS: addDoc('user_notifications') for Admin
    FS-->>A: Real-time Alert: Low Stock
```

---

## 4. Security & Registration Logic (Flowchart)
This diagram uses Mermaid's flowchart syntax to show the registration security layers.

```mermaid
flowchart TD
    Start([User Opens Registration]) --> Role{Select Role?}
    Role -->|Customer| Details[Fill Details]
    Role -->|Technician/Admin| Invite[Invite Code Required]
    
    Invite --> EnterCode[Enter Code]
    EnterCode --> Valid{Validate Code}
    
    Valid -->|Invalid| Error[Show Error]
    Error --> EnterCode
    
    Valid -->|Valid| Auth[Create Firebase Auth User]
    Details --> Auth
    
    Auth --> Profile[Create Firestore Profile]
    Profile --> Usage[Mark Code as Used]
    Usage --> Done([Registration Complete])
```

---

## 5. Role-Based Access Control (RBAC)
Visualization of how users are directed based on their assigned role.

```mermaid
graph TD
    Login[User Login] --> CheckRole{Check Role in Firestore}
    
    CheckRole -->|Customer| CustDash[Customer Dashboard]
    CheckRole -->|Technician| TechDash[Technician Dashboard]
    CheckRole -->|Admin| AdminDash[Admin Dashboard]
    
    subgraph CustomerPrivileges
        CustDash --> C1[Book Service]
        CustDash --> C2[My Cars]
    end
    
    subgraph TechnicianPrivileges
        TechDash --> T1[View Available Jobs]
        TechDash --> T2[Update Job Status]
    end
    
    subgraph AdminPrivileges
        AdminDash --> A1[Manage Users]
        AdminDash --> A2[Invite Code Management]
        AdminDash --> A3[System Analytics]
    end
```

---
