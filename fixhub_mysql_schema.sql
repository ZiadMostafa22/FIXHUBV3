-- =====================================================
-- Fix-Hub MySQL Database Schema
-- Complete relational database schema with all tables and relationships
-- =====================================================

-- Drop existing database if exists
DROP DATABASE IF EXISTS fixhub_db;
CREATE DATABASE fixhub_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fixhub_db;

-- =====================================================
-- 1. USERS TABLE
-- =====================================================
CREATE TABLE users (
    id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    role ENUM('customer', 'technician', 'admin', 'cashier') NOT NULL,
    profile_image_url VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    preferences JSON,
    invite_code_id VARCHAR(255),
    invite_code VARCHAR(8),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_invite_code_id (invite_code_id)
) ENGINE=InnoDB;

-- =====================================================
-- 2. INVITE CODES TABLE
-- =====================================================
CREATE TABLE invite_codes (
    id VARCHAR(255) PRIMARY KEY,
    code VARCHAR(8) NOT NULL UNIQUE,
    role ENUM('technician', 'cashier', 'admin') NOT NULL,
    max_uses INT NOT NULL,
    used_count INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) NOT NULL,
    INDEX idx_code (code),
    INDEX idx_created_by (created_by),
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- 3. INVITE CODE USAGE TRACKING (Many-to-Many)
-- =====================================================
CREATE TABLE invite_code_usage (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invite_code_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    used_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invite_code_id) REFERENCES invite_codes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_code_user (invite_code_id, user_id)
) ENGINE=InnoDB;

-- Add foreign key constraint to users table
ALTER TABLE users 
ADD CONSTRAINT fk_users_invite_code 
FOREIGN KEY (invite_code_id) REFERENCES invite_codes(id) ON DELETE SET NULL;

-- =====================================================
-- 4. CARS TABLE
-- =====================================================
CREATE TABLE cars (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    color VARCHAR(50) NOT NULL,
    license_plate VARCHAR(50) NOT NULL UNIQUE,
    type ENUM('sedan', 'suv', 'hatchback', 'coupe', 'convertible', 'truck', 'van') NOT NULL,
    vin VARCHAR(17),
    engine_type VARCHAR(100),
    mileage INT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_license_plate (license_plate),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- 5. CAR IMAGES TABLE (One-to-Many)
-- =====================================================
CREATE TABLE car_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    car_id VARCHAR(255) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
    INDEX idx_car_id (car_id)
) ENGINE=InnoDB;

-- =====================================================
-- 6. SERVICES CATALOG TABLE
-- =====================================================
CREATE TABLE services (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('part', 'labor', 'service') NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_type (type),
    INDEX idx_category (category),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB;

-- =====================================================
-- 7. OFFERS TABLE
-- =====================================================
CREATE TABLE offers (
    id VARCHAR(255) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    type ENUM('announcement', 'discount', 'promotion', 'news') NOT NULL,
    image_url VARCHAR(500),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    discount_percentage INT,
    code VARCHAR(50) UNIQUE,
    terms TEXT,
    INDEX idx_code (code),
    INDEX idx_is_active (is_active),
    INDEX idx_created_by (created_by),
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    CHECK (discount_percentage >= 0 AND discount_percentage <= 100)
) ENGINE=InnoDB;

-- =====================================================
-- 8. BOOKINGS TABLE
-- =====================================================
CREATE TABLE bookings (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    car_id VARCHAR(255) NOT NULL,
    service_id VARCHAR(255),
    maintenance_type ENUM('regular', 'repair', 'inspection', 'emergency') NOT NULL,
    scheduled_date TIMESTAMP NOT NULL,
    time_slot VARCHAR(50) NOT NULL,
    status ENUM('pending', 'confirmed', 'inProgress', 'completedPendingPayment', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
    description TEXT,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    
    -- Service Details
    labor_cost DECIMAL(10, 2),
    tax DECIMAL(10, 2),
    total_cost DECIMAL(10, 2),
    technician_notes TEXT,
    
    -- Discount/Offer
    offer_code VARCHAR(50),
    offer_title VARCHAR(255),
    discount_percentage INT,
    
    -- Rating
    rating DECIMAL(2, 1),
    rating_comment TEXT,
    rated_at TIMESTAMP NULL,
    
    -- Payment
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    paid_at TIMESTAMP NULL,
    cashier_id VARCHAR(255),
    payment_method ENUM('cash', 'card', 'digital'),
    
    INDEX idx_user_id (user_id),
    INDEX idx_car_id (car_id),
    INDEX idx_status (status),
    INDEX idx_scheduled_date (scheduled_date),
    INDEX idx_cashier_id (cashier_id),
    INDEX idx_offer_code (offer_code),
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL,
    FOREIGN KEY (cashier_id) REFERENCES users(id) ON DELETE SET NULL,
    
    CHECK (rating >= 1.0 AND rating <= 5.0),
    CHECK (discount_percentage >= 0 AND discount_percentage <= 100)
) ENGINE=InnoDB;

-- =====================================================
-- 9. BOOKING SERVICE ITEMS (Many-to-Many with details)
-- =====================================================
CREATE TABLE booking_service_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id VARCHAR(255) NOT NULL,
    service_item_id VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    type ENUM('part', 'labor', 'service') NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    description TEXT,
    category VARCHAR(100),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (service_item_id) REFERENCES services(id) ON DELETE SET NULL,
    INDEX idx_booking_id (booking_id)
) ENGINE=InnoDB;

-- =====================================================
-- 10. ASSIGNED TECHNICIANS (Many-to-Many)
-- =====================================================
CREATE TABLE booking_technicians (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id VARCHAR(255) NOT NULL,
    technician_id VARCHAR(255) NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (technician_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_booking_tech (booking_id, technician_id),
    INDEX idx_booking_id (booking_id),
    INDEX idx_technician_id (technician_id)
) ENGINE=InnoDB;

-- =====================================================
-- 11. REFUNDS TABLE
-- =====================================================
CREATE TABLE refunds (
    id VARCHAR(255) PRIMARY KEY,
    booking_id VARCHAR(255) NOT NULL UNIQUE,
    original_amount DECIMAL(10, 2) NOT NULL,
    refund_amount DECIMAL(10, 2) NOT NULL,
    reason TEXT NOT NULL,
    customer_notes TEXT,
    status ENUM('requested', 'approved', 'rejected', 'processed') NOT NULL DEFAULT 'requested',
    requested_by VARCHAR(255) NOT NULL,
    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_by VARCHAR(255),
    approved_at TIMESTAMP NULL,
    processed_at TIMESTAMP NULL,
    original_payment_method VARCHAR(50),
    refund_method VARCHAR(50),
    INDEX idx_booking_id (booking_id),
    INDEX idx_status (status),
    INDEX idx_requested_by (requested_by),
    INDEX idx_approved_by (approved_by),
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (requested_by) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================
-- 12. INVENTORY TABLE
-- =====================================================
CREATE TABLE inventory (
    id VARCHAR(255) PRIMARY KEY,
    service_item_id VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) NOT NULL UNIQUE,
    category ENUM('parts', 'supplies', 'tools') NOT NULL,
    current_stock INT NOT NULL DEFAULT 0,
    low_stock_threshold INT NOT NULL DEFAULT 10,
    reorder_point INT NOT NULL DEFAULT 15,
    unit_cost DECIMAL(10, 2) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    location VARCHAR(255),
    supplier VARCHAR(255),
    supplier_contact VARCHAR(255),
    last_restocked TIMESTAMP NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_sku (sku),
    INDEX idx_category (category),
    INDEX idx_service_item_id (service_item_id),
    FOREIGN KEY (service_item_id) REFERENCES services(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================
-- 13. INVENTORY TRANSACTIONS TABLE
-- =====================================================
CREATE TABLE inventory_transactions (
    id VARCHAR(255) PRIMARY KEY,
    inventory_item_id VARCHAR(255) NOT NULL,
    type ENUM('in', 'out', 'adjustment') NOT NULL,
    quantity INT NOT NULL,
    quantity_before INT NOT NULL,
    quantity_after INT NOT NULL,
    booking_id VARCHAR(255),
    technician_id VARCHAR(255),
    reason TEXT,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) NOT NULL,
    INDEX idx_inventory_item_id (inventory_item_id),
    INDEX idx_booking_id (booking_id),
    INDEX idx_created_by (created_by),
    INDEX idx_type (type),
    FOREIGN KEY (inventory_item_id) REFERENCES inventory(id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL,
    FOREIGN KEY (technician_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- 14. LOW STOCK ALERTS TABLE
-- =====================================================
CREATE TABLE low_stock_alerts (
    id VARCHAR(255) PRIMARY KEY,
    inventory_item_id VARCHAR(255) NOT NULL,
    current_stock INT NOT NULL,
    threshold INT NOT NULL,
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_inventory_item_id (inventory_item_id),
    INDEX idx_is_resolved (is_resolved),
    FOREIGN KEY (inventory_item_id) REFERENCES inventory(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- 15. USER NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE user_notifications (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    type ENUM('push', 'inApp') NOT NULL,
    category ENUM('booking', 'payment', 'reminder', 'system') NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    booking_id VARCHAR(255),
    car_id VARCHAR(255),
    metadata JSON,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_category (category),
    INDEX idx_sent_at (sent_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL,
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================
-- SAMPLE DATA INSERTION (Optional)
-- =====================================================

-- Insert sample admin user
INSERT INTO users (id, email, name, phone, role, is_active) 
VALUES ('admin-001', 'admin@fixhub.com', 'System Admin', '+201234567890', 'admin', TRUE);

-- Insert sample invite code
INSERT INTO invite_codes (id, code, role, max_uses, used_count, is_active, created_by)
VALUES ('code-001', 'TECH2024', 'technician', 10, 0, TRUE, 'admin-001');

-- Insert sample service
INSERT INTO services (id, name, type, price, description, category, is_active)
VALUES ('service-001', 'Oil Change', 'service', 150.00, 'Full synthetic oil change', 'Maintenance', TRUE);

-- =====================================================
-- USEFUL VIEWS
-- =====================================================

-- View: Active Bookings with Customer and Car Details
CREATE VIEW active_bookings_view AS
SELECT 
    b.id AS booking_id,
    b.status,
    b.scheduled_date,
    b.maintenance_type,
    u.name AS customer_name,
    u.phone AS customer_phone,
    c.make AS car_make,
    c.model AS car_model,
    c.license_plate,
    b.total_cost,
    b.is_paid
FROM bookings b
JOIN users u ON b.user_id = u.id
JOIN cars c ON b.car_id = c.id
WHERE b.status IN ('pending', 'confirmed', 'inProgress', 'completedPendingPayment');

-- View: Low Stock Items
CREATE VIEW low_stock_items_view AS
SELECT 
    i.id,
    i.name,
    i.sku,
    i.current_stock,
    i.low_stock_threshold,
    i.reorder_point,
    i.supplier,
    i.supplier_contact
FROM inventory i
WHERE i.current_stock <= i.low_stock_threshold
AND i.is_active = TRUE;

-- View: Pending Refunds
CREATE VIEW pending_refunds_view AS
SELECT 
    r.id AS refund_id,
    r.refund_amount,
    r.reason,
    r.status,
    r.requested_at,
    b.id AS booking_id,
    u.name AS customer_name,
    cashier.name AS requested_by_name
FROM refunds r
JOIN bookings b ON r.booking_id = b.id
JOIN users u ON b.user_id = u.id
JOIN users cashier ON r.requested_by = cashier.id
WHERE r.status = 'requested';

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

DELIMITER //

-- Procedure: Update Inventory Stock
CREATE PROCEDURE update_inventory_stock(
    IN p_inventory_id VARCHAR(255),
    IN p_quantity INT,
    IN p_type ENUM('in', 'out', 'adjustment'),
    IN p_booking_id VARCHAR(255),
    IN p_created_by VARCHAR(255),
    IN p_reason TEXT
)
BEGIN
    DECLARE v_current_stock INT;
    DECLARE v_new_stock INT;
    DECLARE v_transaction_id VARCHAR(255);
    
    -- Get current stock
    SELECT current_stock INTO v_current_stock 
    FROM inventory 
    WHERE id = p_inventory_id;
    
    -- Calculate new stock
    IF p_type = 'in' THEN
        SET v_new_stock = v_current_stock + p_quantity;
    ELSEIF p_type = 'out' THEN
        SET v_new_stock = v_current_stock - p_quantity;
    ELSE
        SET v_new_stock = p_quantity;
    END IF;
    
    -- Update inventory
    UPDATE inventory 
    SET current_stock = v_new_stock,
        last_restocked = IF(p_type = 'in', NOW(), last_restocked),
        updated_at = NOW()
    WHERE id = p_inventory_id;
    
    -- Create transaction record
    SET v_transaction_id = UUID();
    INSERT INTO inventory_transactions (
        id, inventory_item_id, type, quantity, 
        quantity_before, quantity_after, booking_id, 
        created_by, reason, created_at
    ) VALUES (
        v_transaction_id, p_inventory_id, p_type, p_quantity,
        v_current_stock, v_new_stock, p_booking_id,
        p_created_by, p_reason, NOW()
    );
    
    -- Check if low stock alert needed
    IF v_new_stock <= (SELECT low_stock_threshold FROM inventory WHERE id = p_inventory_id) THEN
        INSERT INTO low_stock_alerts (id, inventory_item_id, current_stock, threshold, created_at)
        SELECT UUID(), p_inventory_id, v_new_stock, low_stock_threshold, NOW()
        FROM inventory 
        WHERE id = p_inventory_id;
    END IF;
END //

DELIMITER ;

-- =====================================================
-- TRIGGERS
-- =====================================================

DELIMITER //

-- Trigger: Auto-increment invite code usage count
CREATE TRIGGER after_invite_code_usage_insert
AFTER INSERT ON invite_code_usage
FOR EACH ROW
BEGIN
    UPDATE invite_codes 
    SET used_count = used_count + 1
    WHERE id = NEW.invite_code_id;
END //

-- Trigger: Validate booking rating
CREATE TRIGGER before_booking_rating_update
BEFORE UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF NEW.rating IS NOT NULL THEN
        IF NEW.rating < 1.0 OR NEW.rating > 5.0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rating must be between 1.0 and 5.0';
        END IF;
    END IF;
END //

DELIMITER ;

-- =====================================================
-- END OF SCHEMA
-- =====================================================
