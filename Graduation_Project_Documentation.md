# Fix-Hub: Complete Project Documentation

> **Project Name:** Fix-Hub - Car Maintenance Management System  
> **Document Version:** 2.0  
> **Last Updated:** December 27, 2025  
> **Technology Stack:** Flutter (Dart), Firebase (Auth, Firestore, Storage), Gemini AI  
> **Architecture:** MVVM (Model-View-ViewModel)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [User Roles & Permissions](#3-user-roles--permissions)
4. [Features by Role](#4-features-by-role)
5. [Database Schema](#5-database-schema)
6. [Application Modules](#6-application-modules)
7. [Core Workflows](#7-core-workflows)
8. [Security & Authentication](#8-security--authentication)
9. [Notification System](#9-notification-system)
10. [Technology Stack Details](#10-technology-stack-details)

---

## 1. Project Overview

### 1.1 What is Fix-Hub?

Fix-Hub is a comprehensive **Car Maintenance Management System** designed to digitize and streamline the entire car service lifecycle. It connects **Customers** who need car maintenance with **Technicians** who perform the work, managed by **Admins** for oversight, and **Cashiers** for payment processing.

### 1.2 Problem Statement

Traditional car maintenance shops face challenges with:
- Manual booking and scheduling
- Paper-based record keeping
- Lack of real-time status updates for customers
- Inefficient inventory management
- Difficulty tracking technician performance
- No centralized payment and refund system

### 1.3 Solution

Fix-Hub provides:
- **Digital booking system** with real-time status tracking
- **Automated inventory management** with low-stock alerts
- **Multi-role access** for customers, technicians, admins, and cashiers
- **AI-powered chatbot** for customer support
- **Comprehensive reporting** for business analytics
- **Secure payment processing** with refund workflows

---

## 2. System Architecture

### 2.1 Architecture Pattern: MVVM

```
┌─────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Widgets   │  │   Screens   │  │   Dialogs   │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         └────────────────┼────────────────┘                      │
│                          ▼                                       │
│              ┌─────────────────────┐                             │
│              │    ViewModels       │  (State Management)         │
│              └──────────┬──────────┘                             │
└─────────────────────────┼───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ Repositories│  │   Services  │  │   Models    │              │
│  └──────┬──────┘  └──────┬──────┘  └─────────────┘              │
│         └────────────────┼──────────────────────────────────────┘
│                          ▼                                       │
│              ┌─────────────────────┐                             │
│              │   Firebase Backend  │                             │
│              │  (Auth, Firestore,  │                             │
│              │   Storage, FCM)     │                             │
│              └─────────────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Directory Structure

```
lib/
├── core/                    # Core utilities and shared components
│   ├── models/              # Data models (User, Car, Booking, etc.)
│   ├── services/            # Firebase services, API clients
│   ├── utils/               # Helpers, constants, validators
│   └── widgets/             # Reusable UI components
│
├── features/                # Feature modules by domain
│   ├── admin/               # Admin dashboard & management
│   ├── auth/                # Authentication (Login, Register)
│   ├── booking/             # Booking creation & management
│   ├── car/                 # Car registration & management
│   ├── cashier/             # Payment processing & refunds
│   ├── chatbot/             # AI-powered chatbot (Gemini)
│   ├── customer/            # Customer dashboard & features
│   ├── inventory/           # Stock management
│   ├── refunds/             # Refund processing
│   ├── splash/              # App splash screen
│   ├── technician/          # Technician job management
│   └── user/                # User profile management
│
├── main.dart                # App entry point
└── firebase_options.dart    # Firebase configuration
```

---

## 3. User Roles & Permissions

### 3.1 Role Hierarchy

| Role | Access Level | Registration Method |
|------|--------------|---------------------|
| **Customer** | Basic | Self-registration (no code required) |
| **Technician** | Staff | Invite code required (role=technician) |
| **Cashier** | Staff | Invite code required (role=cashier) |
| **Admin** | Full | Invite code required (role=admin) |

### 3.2 Role Capabilities Matrix

| Feature | Customer | Technician | Cashier | Admin |
|---------|----------|------------|---------|-------|
| Register Cars | ✅ | ❌ | ❌ | ❌ |
| Book Services | ✅ | ❌ | ❌ | ❌ |
| Track Bookings | ✅ | ❌ | ❌ | ✅ |
| Rate Services | ✅ | ❌ | ❌ | ❌ |
| AI Chatbot | ✅ | ❌ | ❌ | ❌ |
| View Available Jobs | ❌ | ✅ | ❌ | ✅ |
| Start/Complete Jobs | ❌ | ✅ | ❌ | ❌ |
| Add Service Items | ❌ | ✅ | ❌ | ❌ |
| Process Payments | ❌ | ❌ | ✅ | ❌ |
| Initiate Refunds | ❌ | ❌ | ✅ | ❌ |
| Approve/Reject Refunds | ❌ | ❌ | ❌ | ✅ |
| Manage Users | ❌ | ❌ | ❌ | ✅ |
| Generate Invite Codes | ❌ | ❌ | ❌ | ✅ |
| Create Offers | ❌ | ❌ | ❌ | ✅ |
| View Reports | ❌ | ✅ | ✅ | ✅ |
| Manage Inventory | ❌ | ❌ | ❌ | ✅ |

---

## 4. Features by Role

### 4.1 Customer Features

| Feature | Description |
|---------|-------------|
| **Registration** | Self-register with email, password, name, and phone |
| **Car Management** | Add, edit, delete registered vehicles with details (make, model, year, license plate, type) |
| **Service Catalog** | Browse available services by category with search and filters |
| **Booking Creation** | Book maintenance with car selection, service selection, date/time scheduling, and optional discount codes |
| **Booking Tracking** | Real-time status updates (pending → in progress → completed) |
| **Invoice Download** | Download PDF invoices for completed and paid bookings |
| **Service Rating** | Rate completed services (1-5 stars) with comments |
| **AI Chatbot** | Get support and answers via Gemini-powered chatbot |
| **Notifications** | Receive alerts for booking status changes, offers, and payments |
| **Offer Redemption** | Apply promotional discount codes during booking |

### 4.2 Technician Features

| Feature | Description |
|---------|-------------|
| **Registration** | Register using admin-generated invite code |
| **Job Board** | View all pending bookings available for pickup |
| **My Schedule** | View assigned tasks for today/week |
| **Start Job** | Pick up pending jobs and start working |
| **Job Details** | View customer info, car details, technical notes, and service history |
| **Add Service Items** | Add parts/labor from inventory during service (auto-updates stock) |
| **Complete Job** | Mark job as completed with technician notes |
| **Performance Stats** | View monthly earnings, average rating, and job completion stats |
| **Notifications** | Receive alerts for new jobs and rating feedback |

### 4.3 Cashier Features

| Feature | Description |
|---------|-------------|
| **Registration** | Register using admin-generated invite code |
| **Payment Queue** | View bookings awaiting payment (status=completedPendingPayment) |
| **Process Payment** | Accept cash, card, or digital payments |
| **Cost Breakdown** | Display subtotal, discounts, tax, and final total |
| **Invoice Generation** | Auto-generate and send invoice to customer after payment |
| **Refund Initiation** | Create refund requests for admin approval |
| **Refund Processing** | Complete approved refunds |
| **Transaction History** | Search and browse past transactions |
| **Daily Settlement** | View shift revenue summary by payment method |
| **Profit Reports** | Generate revenue reports by date range |

### 4.4 Admin Features

| Feature | Description |
|---------|-------------|
| **Registration** | Register using admin-generated invite code |
| **Dashboard** | Real-time stats (active bookings, revenue, idle technicians) |
| **User Management** | View all users, activate/deactivate accounts, filter by role |
| **Invite Code Generation** | Create invite codes for staff registration with role and max uses |
| **Refund Approval** | Review and approve/reject refund requests |
| **Promotional Offers** | Create discount offers with codes, percentages, and validity periods |
| **Inventory Management** | View all stock, low-stock alerts, supplier info |
| **System Reports** | Generate profit, performance, and booking reports |
| **Service Catalog** | Manage available services (add, edit, deactivate) |
| **Notifications** | Receive alerts for refund requests and low stock |

---

## 5. Database Schema

### 5.1 Collections Overview

Fix-Hub uses **Firebase Cloud Firestore** with 11 collections:

| # | Collection | Purpose | Key Fields |
|---|------------|---------|------------|
| 1 | `users` | User accounts | id, email, name, phone, role, isActive |
| 2 | `cars` | Customer vehicles | id, userId, make, model, year, licensePlate, type |
| 3 | `bookings` | Service appointments | id, userId, carId, status, serviceItems[], isPaid, rating |
| 4 | `services` | Service catalog | id, name, type, price, category, isActive |
| 5 | `inventory` | Stock items | id, name, sku, currentStock, lowStockThreshold |
| 6 | `inventory_transactions` | Stock movements | id, inventoryItemId, type (in/out), quantity |
| 7 | `low_stock_alerts` | Stock alerts | id, inventoryItemId, currentStock, isResolved |
| 8 | `refunds` | Refund requests | id, bookingId, status, refundAmount, reason |
| 9 | `offers` | Promotional offers | id, title, code, discountPercentage, isActive |
| 10 | `invite_codes` | Staff registration codes | id, code, role, maxUses, usedCount |
| 11 | `user_notifications` | In-app notifications | id, userId, title, message, read |

### 5.2 Key Relationships

```
USER ─────┬──────> CARS (1:N) ──────> BOOKINGS (1:N)
          │                                  │
          │                                  ├──> REFUNDS (1:1)
          │                                  ├──> SERVICE_ITEMS (embedded)
          │                                  └──> NOTIFICATIONS (1:N)
          │
          ├──────> INVITE_CODES (uses)
          ├──────> OFFERS (creates - admin)
          └──────> NOTIFICATIONS (1:N)

INVENTORY ────────> TRANSACTIONS (1:N)
          ────────> LOW_STOCK_ALERTS (1:N)
```

### 5.3 Key Enums

| Enum | Values |
|------|--------|
| **UserRole** | customer, technician, admin, cashier |
| **CarType** | sedan, suv, hatchback, coupe, convertible, truck, van |
| **MaintenanceType** | regular, repair, inspection, emergency |
| **BookingStatus** | pending, confirmed, inProgress, completedPendingPayment, completed, cancelled |
| **PaymentMethod** | cash, card, digital |
| **RefundStatus** | requested, approved, rejected, processed |
| **OfferType** | announcement, discount, promotion, news |

---

## 6. Application Modules

### 6.1 Auth Module (`features/auth/`)

Handles user authentication:
- **Login**: Email/password authentication via Firebase Auth
- **Customer Registration**: Direct registration for customers
- **Staff Registration**: Invite code validation for technicians, cashiers, and admins
- **Session Management**: Persistent login, auto-redirect by role

### 6.2 Booking Module (`features/booking/`)

Manages the booking lifecycle:
- **Create Booking**: Car selection → Service selection → Scheduling → Confirmation
- **Track Booking**: Real-time status updates via Firestore streams
- **Cancel Booking**: Customer-initiated cancellation (if status=pending)
- **Rate Booking**: Post-completion rating and feedback

### 6.3 Car Module (`features/car/`)

Vehicle management:
- **Add Car**: Enter make, model, year, color, license plate, type
- **Edit Car**: Update car details
- **Delete Car**: Remove car (if no active bookings)
- **View History**: See maintenance history per car

### 6.4 Chatbot Module (`features/chatbot/`)

AI-powered customer support:
- **Gemini Integration**: Uses Google Gemini API for responses
- **Conversation History**: Stores chat history in Firestore
- **Context-Aware**: Understands car maintenance domain

### 6.5 Inventory Module (`features/inventory/`)

Stock management:
- **Stock View**: Browse all inventory items
- **Low Stock Alerts**: Automatic alerts when stock falls below threshold
- **Transactions**: Track stock in/out movements logged by technicians

### 6.6 Refunds Module (`features/refunds/`)

Refund workflow:
- **Initiation**: Cashier creates refund request
- **Approval**: Admin reviews and approves/rejects
- **Processing**: Cashier completes approved refund

---

## 7. Core Workflows

### 7.1 Booking Lifecycle

```
┌─────────────┐    ┌─────────────┐    ┌───────────────────────┐    ┌─────────────┐    ┌─────────────┐
│   PENDING   │───>│ IN_PROGRESS │───>│ COMPLETED_PENDING_PAY │───>│  COMPLETED  │───>│   RATED     │
└─────────────┘    └─────────────┘    └───────────────────────┘    └─────────────┘    └─────────────┘
    │                    │                        │                        │
    │ Customer           │ Technician             │ Cashier                │ Customer
    │ creates            │ starts job             │ processes              │ rates
    │                    │ adds items             │ payment                │ service
    │                    │ completes              │                        │
    v                    v                        v                        v
 Technicians          Customer               Invoice sent              Technician
 notified             notified              to customer               notified
```

### 7.2 Refund Workflow

```
┌───────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   REQUESTED   │───>│  APPROVED   │───>│  PROCESSED  │───>│   COMPLETE  │
└───────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
        │                   │                   │
        │ Cashier           │ Admin             │ Cashier
        │ initiates         │ approves          │ processes
        v                   v                   v
    Admin notified    Cashier notified    Customer notified
```

### 7.3 Inventory Transaction Flow

```
Technician adds item to booking
        │
        ▼
┌─────────────────────────────┐
│ Check currentStock >= qty   │
└──────────────┬──────────────┘
               │
       ┌───────┴───────┐
       │ YES           │ NO
       ▼               ▼
   Add item        Show "Out of Stock"
   to booking      error
       │
       ▼
┌─────────────────────────────┐
│ Create inventory_transaction│
│ type=out, quantity=qty      │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Decrement currentStock      │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Is currentStock < threshold?│
└──────────────┬──────────────┘
               │
       ┌───────┴───────┐
       │ YES           │ NO
       ▼               ▼
   Create          Done
   low_stock_alert
   Notify Admin
```

---

## 8. Security & Authentication

### 8.1 Authentication Flow

- **Firebase Authentication** for email/password sign-in
- **Role-based access control** stored in Firestore user document
- **Invite code validation** for staff registration to prevent unauthorized access

### 8.2 Firestore Security Rules

The system uses comprehensive Firestore security rules:

- **Users**: Read own profile, admins can read all
- **Cars**: Customers read/write their own cars only
- **Bookings**: Customers see their bookings, technicians see pending/assigned jobs
- **Refunds**: Cashiers create, admins approve
- **Inventory**: Technicians can read and create transactions
- **Invite Codes**: Only admins can create, users can validate

### 8.3 Data Privacy

- **Customer data** (cars, bookings) is scoped to the user
- **Payment information** is processed but not stored
- **Profile images** stored securely in Firebase Storage

---

## 9. Notification System

### 9.1 Notification Types

| Type | Trigger | Recipients |
|------|---------|------------|
| **New Booking** | Customer creates booking | All technicians |
| **Job Started** | Technician starts job | Customer |
| **Job Completed** | Technician completes job | Customer, Cashier |
| **Payment Processed** | Cashier processes payment | Customer |
| **Rating Received** | Customer rates service | Assigned technician |
| **Refund Requested** | Cashier initiates refund | Admins |
| **Refund Approved/Rejected** | Admin decides on refund | Cashier, Customer |
| **New Offer** | Admin creates promotional offer | All customers |
| **Low Stock Alert** | Stock falls below threshold | Admins |

### 9.2 Notification Delivery

- **In-App**: Stored in `user_notifications` collection, displayed in notification hub
- **Real-time**: Firestore streams for instant updates

---

## 10. Technology Stack Details

### 10.1 Frontend

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform UI framework |
| **Dart** | Programming language |
| **Provider/ChangeNotifier** | State management (MVVM) |
| **Material Design 3** | UI components and theming |

### 10.2 Backend

| Technology | Purpose |
|------------|---------|
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | NoSQL database |
| **Firebase Storage** | File storage (images, PDFs) |
| **Firebase Cloud Messaging** | Push notifications (future) |

### 10.3 AI Integration

| Technology | Purpose |
|------------|---------|
| **Google Gemini API** | AI-powered chatbot responses |

### 10.4 Development Tools

| Tool | Purpose |
|------|---------|
| **VS Code/Android Studio** | IDE |
| **Git** | Version control |
| **Firebase Console** | Backend management |
| **Mermaid** | UML diagram creation |

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| **User Roles** | 4 (Customer, Technician, Cashier, Admin) |
| **Database Collections** | 11 |
| **Feature Modules** | 13 |
| **Use Cases** | 15+ |
| **Activity Diagrams** | 22 |
| **Sequence Diagrams** | 10 |
| **State Diagrams** | 6 |

---

**Document Version:** 2.0  
**Last Updated:** December 27, 2025  
**Project Status:** Complete
