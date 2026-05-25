# Fix-Hub: Enhanced Abstract

## Abstract

The **Fix-Hub** project is a comprehensive car maintenance management system designed to streamline operations for automotive service centers. It provides a digital platform for customers, technicians, cashiers, and administrators to manage bookings, track maintenance history, process payments, and analyze performance metrics. 

Built with **Flutter** for cross-platform mobile development and **Firebase Cloud Firestore** for real-time database management, the system ensures seamless synchronization, role-based security, and an enhanced user experience across multiple platforms including Android, iOS, and web.

### Key Features

#### 🔐 **Multi-Role Authentication System**
- **Four distinct user roles:** Customer, Technician, Admin, and Cashier
- **Invite-code based registration** for staff members (technicians, admins, cashiers)
- **Role-based access control (RBAC)** ensuring secure data access
- Firebase Authentication integration with email/password and social login support

#### 📅 **Advanced Booking Management**
- **Real-time booking system** with status tracking (pending, confirmed, in-progress, completed)
- **Multi-technician assignment** support for complex maintenance tasks
- **Service catalog integration** with dynamic pricing and categorization
- **Offer and discount code application** at booking time
- **Scheduled appointments** with time slot management and conflict prevention

#### 🚗 **Vehicle Management**
- **Comprehensive car profiles** with make, model, year, VIN, and mileage tracking
- **Multiple car registration** per customer account
- **Photo gallery** for vehicle documentation
- **Maintenance history** tracking across all bookings

#### 💰 **Payment & Financial Management**
- **Multi-method payment processing** (cash, card, digital wallets)
- **Automated invoice generation** with PDF download capability
- **Refund request workflow** with cashier initiation and admin approval
- **Real-time profit and revenue reporting** for business analytics
- **Tax calculation and discount application** in billing

#### 🔧 **Inventory & Stock Management**
- **Real-time inventory tracking** with SKU-based item management
- **Automated low-stock alerts** with configurable thresholds
- **Inventory transaction logging** (in, out, adjustment) with audit trail
- **Service-to-inventory linking** for parts and supplies
- **Supplier contact management** and reorder point automation

#### 🤖 **AI-Powered Customer Support**
- **Gemini AI chatbot integration** for 24/7 customer assistance
- **Context-aware conversations** with maintenance history access
- **Automated FAQ responses** and service recommendations
- **Conversation history persistence** in Firestore

#### 📊 **Analytics & Reporting**
- **Technician performance metrics** with job completion rates and ratings
- **Revenue and profit analysis** with date range filtering
- **Booking trends visualization** for capacity planning
- **Customer satisfaction tracking** through rating and feedback system
- **Inventory turnover reports** for stock optimization

#### 🔔 **Real-Time Notifications**
- **Push and in-app notifications** for booking updates
- **Multi-channel notification system** (booking, payment, reminder, system alerts)
- **Role-specific notifications** (e.g., technicians notified of new jobs, admins of refund requests)
- **Firebase Cloud Messaging (FCM)** integration for instant delivery

#### 🎁 **Promotional System**
- **Admin-created offers** with custom discount percentages
- **Unique promo codes** with usage tracking
- **Time-bound promotions** with start/end date management
- **Customer notification** for new offers and announcements

### Technical Architecture

#### **Frontend**
- **Flutter Framework** for cross-platform development (Android, iOS, Web)
- **MVVM (Model-View-ViewModel)** architecture pattern for clean separation of concerns
- **Provider/Riverpod** state management for reactive UI updates
- **Material Design 3** with custom theming and responsive layouts

#### **Backend & Database**
- **Firebase Cloud Firestore** as the primary NoSQL database
- **15 core collections** with complex relationships and foreign key constraints
- **Real-time data synchronization** across all connected clients
- **Firestore Security Rules** for granular access control
- **Cloud Functions** for server-side business logic and triggers

#### **Database Schema Highlights**
- **35+ relationships** between entities ensuring data integrity
- **Junction tables** for many-to-many relationships (booking-technicians, invite code usage)
- **One-to-one relationships** for refunds and inventory linking
- **Comprehensive indexing** on foreign keys and frequently queried fields
- **Audit trails** with created_at, updated_at, and user tracking

#### **AI & External Services**
- **Google Gemini AI API** for intelligent chatbot responses
- **Firebase Storage** for image and document management
- **PDF generation libraries** for invoice creation
- **Payment gateway integration** (Stripe/Paymob) for digital transactions

### System Capabilities

#### **For Customers**
- Register and manage multiple vehicles
- Book maintenance services with real-time availability
- Track service status from pending to completion
- Rate and review completed services
- Download invoices and payment receipts
- Chat with AI assistant for instant support
- Apply promotional codes for discounts

#### **For Technicians**
- View available jobs in real-time
- Accept and start work on bookings
- Add parts and services during maintenance
- Update inventory with automatic stock deduction
- Complete jobs with detailed notes
- View performance metrics and ratings

#### **For Cashiers**
- Process payments with multiple methods
- Generate and send invoices to customers
- Initiate refund requests with documentation
- View daily/monthly revenue reports
- Track pending payments

#### **For Administrators**
- Generate invite codes for staff registration
- Activate/deactivate user accounts
- Approve or reject refund requests
- Create promotional offers and announcements
- Monitor system-wide analytics and reports
- Manage inventory stock levels and suppliers
- View low-stock alerts and reorder recommendations

### Security & Compliance

- **End-to-end encryption** for sensitive data transmission
- **Role-based access control (RBAC)** at database and application levels
- **Firebase Security Rules** preventing unauthorized data access
- **Audit logging** for all critical operations (payments, refunds, inventory changes)
- **Data validation** on both client and server sides
- **Secure invite-code system** for staff onboarding

### Performance Optimizations

- **Lazy loading** for large data sets
- **Pagination** for booking and transaction lists
- **Indexed queries** for fast data retrieval
- **Caching strategies** for frequently accessed data
- **Optimistic UI updates** for better user experience
- **Background sync** for offline capability

### Project Scope

The Fix-Hub system encompasses the complete lifecycle of automotive service management, from initial customer registration through service delivery, payment processing, and post-service feedback. The platform supports unlimited users, vehicles, and transactions, making it scalable for small workshops to large service center chains.

### Conclusion

Fix-Hub represents a modern, scalable, and feature-rich solution for automotive service management. By leveraging cutting-edge technologies like Flutter, Firebase, and AI, the system delivers a seamless experience for all stakeholders while maintaining robust security, real-time synchronization, and comprehensive business intelligence capabilities. The modular architecture and well-defined database schema ensure easy maintenance, extensibility, and future enhancements.

---

**Technologies:** Flutter, Dart, Firebase (Firestore, Auth, Storage, Cloud Functions), Gemini AI, MySQL (for ERD modeling), MVVM Architecture

**Platforms:** Android, iOS, Web

**Database:** 15 Tables, 35+ Relationships, Real-time Synchronization

**Roles:** Customer, Technician, Cashier, Administrator

**Last Updated:** January 19, 2026
