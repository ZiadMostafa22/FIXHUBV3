# Fix-Hub Entity Relationship Diagram (ERD)

## Complete Database Schema - Mermaid ERD

```mermaid
erDiagram
    users ||--o{ cars : owns
    users ||--o{ bookings : creates
    users ||--o{ user_notifications : receives
    users ||--o{ offers : "creates(admin)"
    users }o--|| invite_codes : uses
    
    invite_codes ||--o{ invite_code_usage : tracks
    users ||--o{ invite_code_usage : "used_by"
    
    cars ||--o{ bookings : has
    cars ||--o{ car_images : has
    cars ||--o{ user_notifications : "relates_to"
    
    services ||--o{ booking_service_items : "used_in"
    services ||--o| inventory : "linked_to"
    
    bookings ||--o{ booking_service_items : contains
    bookings ||--o{ booking_technicians : "assigned_to"
    bookings ||--|| refunds : "may_have"
    bookings ||--o{ user_notifications : triggers
    bookings ||--o{ inventory_transactions : "uses_items"
    
    inventory ||--o{ inventory_transactions : has
    inventory ||--o{ low_stock_alerts : triggers
    
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

| Relationship | Cardinality | Description |
|--------------|-------------|-------------|
| **User → Cars** | 1:N | One user can own multiple cars |
| **User → Bookings** | 1:N | One user can create multiple bookings |
| **Car → Bookings** | 1:N | One car can have multiple service bookings |
| **Booking → Refunds** | 1:1 | One booking can have at most one refund |
| **Booking → Technicians** | N:M | Many bookings can be assigned to many technicians |
| **Booking → Service Items** | 1:N | One booking can contain multiple service items |
| **User → Notifications** | 1:N | One user receives many notifications |
| **Inventory → Transactions** | 1:N | One inventory item has many transactions |
| **Inventory → Alerts** | 1:N | One inventory item can trigger multiple alerts |
| **Offer → Bookings** | 1:N | One offer can be used by many bookings |
| **InviteCode → Users** | 1:N | One invite code can be used by many users |

## Key Features

### 🔑 Primary Keys (PK)
- All tables use `id` as primary key
- Unique constraints on: `email`, `code`, `license_plate`, `sku`, `booking_id` (in refunds)

### 🔗 Foreign Keys (FK)
- **users**: `invite_code_id`
- **cars**: `user_id`
- **bookings**: `user_id`, `car_id`, `service_id`, `cashier_id`
- **booking_technicians**: `booking_id`, `technician_id`
- **refunds**: `booking_id`, `requested_by`, `approved_by`
- **inventory_transactions**: `inventory_item_id`, `booking_id`, `technician_id`, `created_by`
- **user_notifications**: `user_id`, `booking_id`, `car_id`

### 📊 Indexes
- All foreign keys are indexed
- Additional indexes on frequently queried fields (status, dates, roles)

---

**Last Updated:** January 19, 2026
