# Fix-Hub Complete Database ERD - Mermaid

## Complete Entity Relationship Diagram with All Tables and Relationships

```mermaid
erDiagram
    %% ========================================
    %% PRIMARY RELATIONSHIPS
    %% ========================================
    
    %% Users Core Relationships
    users ||--o{ cars : "owns"
    users ||--o{ bookings : "creates"
    users ||--o{ user_notifications : "receives"
    users ||--o{ offers : "creates_admin"
    users ||--o{ invite_codes : "generates_admin"
    users }o--|| invite_codes : "registered_with"
    
    %% Invite Code Relationships
    invite_codes ||--o{ invite_code_usage : "tracks_usage"
    users ||--o{ invite_code_usage : "used_by"
    
    %% Car Relationships
    cars ||--o{ bookings : "has_service"
    cars ||--o{ car_images : "has_photos"
    cars ||--o{ user_notifications : "relates_to"
    
    %% Service Relationships
    services ||--o{ booking_service_items : "used_in_booking"
    services ||--o| inventory : "linked_to_stock"
    
    %% Booking Core Relationships
    bookings ||--o{ booking_service_items : "contains_items"
    bookings ||--o{ booking_technicians : "assigned_techs"
    bookings ||--|| refunds : "may_have_refund"
    bookings ||--o{ user_notifications : "triggers_notification"
    bookings ||--o{ inventory_transactions : "uses_inventory"
    
    %% Booking-User Relationships
    users ||--o{ booking_technicians : "works_on_technician"
    users ||--o{ bookings : "processes_payment_cashier"
    
    %% Refund Relationships
    users ||--o{ refunds : "requests_refund_cashier"
    users ||--o{ refunds : "approves_refund_admin"
    
    %% Inventory Relationships
    inventory ||--o{ inventory_transactions : "has_movements"
    inventory ||--o{ low_stock_alerts : "triggers_alert"
    
    %% Inventory Transaction Relationships
    users ||--o{ inventory_transactions : "performs_transaction"
    users ||--o{ inventory_transactions : "created_by_user"
    
    %% ========================================
    %% TABLE DEFINITIONS
    %% ========================================
    
    users {
        varchar id PK
        varchar email UK
        varchar name
        varchar phone
        enum role
        varchar profile_image_url
        boolean is_active
        json preferences
        varchar invite_code_id FK
        varchar invite_code
        timestamp created_at
        timestamp updated_at
    }
    
    invite_codes {
        varchar id PK
        varchar code UK
        enum role
        int max_uses
        int used_count
        boolean is_active
        timestamp created_at
        varchar created_by FK
    }
    
    invite_code_usage {
        int id PK
        varchar invite_code_id FK
        varchar user_id FK
        timestamp used_at
    }
    
    cars {
        varchar id PK
        varchar user_id FK
        varchar make
        varchar model
        int year
        varchar color
        varchar license_plate UK
        enum type
        varchar vin
        varchar engine_type
        int mileage
        timestamp created_at
        timestamp updated_at
    }
    
    car_images {
        int id PK
        varchar car_id FK
        varchar image_url
        timestamp uploaded_at
    }
    
    services {
        varchar id PK
        varchar name
        enum type
        decimal price
        text description
        varchar category
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }
    
    offers {
        varchar id PK
        varchar title
        text description
        enum type
        varchar image_url
        timestamp start_date
        timestamp end_date
        boolean is_active
        varchar created_by FK
        timestamp created_at
        timestamp updated_at
        int discount_percentage
        varchar code UK
        text terms
    }
    
    bookings {
        varchar id PK
        varchar user_id FK
        varchar car_id FK
        varchar service_id FK
        enum maintenance_type
        timestamp scheduled_date
        varchar time_slot
        enum status
        text description
        text notes
        timestamp created_at
        timestamp updated_at
        timestamp started_at
        timestamp completed_at
        decimal labor_cost
        decimal tax
        decimal total_cost
        text technician_notes
        varchar offer_code
        varchar offer_title
        int discount_percentage
        decimal rating
        text rating_comment
        timestamp rated_at
        boolean is_paid
        timestamp paid_at
        varchar cashier_id FK
        enum payment_method
    }
    
    booking_service_items {
        int id PK
        varchar booking_id FK
        varchar service_item_id FK
        varchar name
        enum type
        decimal price
        int quantity
        text description
        varchar category
    }
    
    booking_technicians {
        int id PK
        varchar booking_id FK
        varchar technician_id FK
        timestamp assigned_at
    }
    
    refunds {
        varchar id PK
        varchar booking_id FK_UK
        decimal original_amount
        decimal refund_amount
        text reason
        text customer_notes
        enum status
        varchar requested_by FK
        timestamp requested_at
        varchar approved_by FK
        timestamp approved_at
        timestamp processed_at
        varchar original_payment_method
        varchar refund_method
    }
    
    inventory {
        varchar id PK
        varchar service_item_id FK
        varchar name
        varchar sku UK
        enum category
        int current_stock
        int low_stock_threshold
        int reorder_point
        decimal unit_cost
        decimal unit_price
        varchar location
        varchar supplier
        varchar supplier_contact
        timestamp last_restocked
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }
    
    inventory_transactions {
        varchar id PK
        varchar inventory_item_id FK
        enum type
        int quantity
        int quantity_before
        int quantity_after
        varchar booking_id FK
        varchar technician_id FK
        text reason
        text notes
        timestamp created_at
        varchar created_by FK
    }
    
    low_stock_alerts {
        varchar id PK
        varchar inventory_item_id FK
        int current_stock
        int threshold
        boolean is_resolved
        timestamp resolved_at
        timestamp created_at
    }
    
    user_notifications {
        varchar id PK
        varchar user_id FK
        enum type
        enum category
        varchar title
        text message
        boolean is_read
        timestamp sent_at
        varchar booking_id FK
        varchar car_id FK
        json metadata
    }
```

## Relationship Summary

### 👤 User Relationships (Central Entity)
| Target Table | Relationship | Type | Description |
|--------------|--------------|------|-------------|
| cars | owns | 1:N | User owns multiple cars |
| bookings | creates | 1:N | User creates bookings as customer |
| bookings | processes_payment | 1:N | Cashier processes payments |
| booking_technicians | works_on | 1:N | Technician assigned to jobs |
| user_notifications | receives | 1:N | User receives notifications |
| offers | creates | 1:N | Admin creates offers |
| invite_codes | generates | 1:N | Admin generates codes |
| invite_codes | registered_with | N:1 | User registered with code |
| invite_code_usage | used_by | 1:N | User uses invite codes |
| refunds | requests | 1:N | Cashier requests refunds |
| refunds | approves | 1:N | Admin approves refunds |
| inventory_transactions | performs | 1:N | User performs transactions |
| inventory_transactions | created_by | 1:N | User creates transaction records |

### 🚗 Car Relationships
| Target Table | Relationship | Type | Description |
|--------------|--------------|------|-------------|
| users | owned_by | N:1 | Car belongs to user |
| bookings | has_service | 1:N | Car has multiple bookings |
| car_images | has_photos | 1:N | Car has multiple images |
| user_notifications | relates_to | 1:N | Notifications about car |

### 📅 Booking Relationships (Core Transaction)
| Target Table | Relationship | Type | Description |
|--------------|--------------|------|-------------|
| users | created_by | N:1 | Customer creates booking |
| users | processed_by | N:1 | Cashier processes payment |
| cars | for_car | N:1 | Booking for specific car |
| services | uses_service | N:1 | Booking uses service catalog |
| booking_service_items | contains | 1:N | Booking contains items |
| booking_technicians | assigned_to | 1:N | Technicians assigned |
| refunds | may_have | 1:1 | May have one refund |
| user_notifications | triggers | 1:N | Triggers notifications |
| inventory_transactions | uses_items | 1:N | Uses inventory items |

### 🔧 Service Relationships
| Target Table | Relationship | Type | Description |
|--------------|--------------|------|-------------|
| booking_service_items | used_in | 1:N | Used in bookings |
| inventory | linked_to | 1:1 | Linked to inventory item |

### 📦 Inventory Relationships
| Target Table | Relationship | Type | Description |
|--------------|--------------|------|-------------|
| services | linked_from | 1:1 | Linked from service |
| inventory_transactions | has_movements | 1:N | Has stock movements |
| low_stock_alerts | triggers_alerts | 1:N | Triggers low stock alerts |

### 💰 Refund Relationships
| Target Table | Relationship | Type | Description |
|--------------|--------------|------|-------------|
| bookings | for_booking | 1:1 | One refund per booking |
| users | requested_by | N:1 | Cashier requests |
| users | approved_by | N:1 | Admin approves |

### 🎁 Offer Relationships
| Target Table | Relationship | Type | Description |
|--------------|--------------|------|-------------|
| users | created_by | N:1 | Admin creates |
| bookings | applied_to | 1:N | Applied to bookings (via code) |

### 🔐 Invite Code Relationships
| Target Table | Relationship | Type | Description |
|--------------|--------------|------|-------------|
| users | created_by | N:1 | Admin creates |
| users | used_by | 1:N | Users register with |
| invite_code_usage | tracks | 1:N | Tracks usage |

## Database Statistics

- **Total Tables:** 15
- **Total Relationships:** 35+
- **Many-to-Many:** 2 (booking_technicians, invite_code_usage)
- **One-to-One:** 2 (booking-refund, service-inventory)
- **One-to-Many:** 31+

## Key Features

### 🔑 Primary Keys
All tables use `id` as primary key (varchar for main entities, int for junction tables)

### 🔗 Foreign Keys
- **users** referenced by: 12 tables
- **bookings** referenced by: 6 tables
- **cars** referenced by: 3 tables
- **inventory** referenced by: 2 tables

### 📊 Indexes
- All foreign keys are indexed
- Unique constraints on: email, code, license_plate, sku
- Additional indexes on status fields and dates

---

**Last Updated:** January 19, 2026  
**Total Entities:** 15 Tables  
**Total Relationships:** 35+ Foreign Key Relationships
