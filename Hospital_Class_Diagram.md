# Hospital Management System - Class Diagram

## Complete Class Diagram

```mermaid
classDiagram
    %% Core User Classes
    class User {
        -int user_id
        -string name
        -string phone
        -string email
        -string password
        -string role
        -datetime created_at
        -datetime updated_at
        +login()
    }
    
    class Patient {
        -int patient_id
        -int user_id
        -date birth_date
        -string gender
        -string address
        +getAppointments()
    }
    
    class Doctor {
        -int doctor_id
        -int user_id
        -string specialization
        -int years_of_experience
        -int clinic_room
        +writePrescription()
    }
    
    class Receptionist {
        -int receptionist_id
        -int user_id
        +approveAppointment()
    }
    
    %% Core System Classes
    class Appointment {
        -int appointment_id
        -int patient_id
        -int doctor_id
        -int receptionist_id
        -date appointment_date
        -time appointment_time
        -string status
        +schedule()
    }
    
    class Prescription {
        -int prescription_id
        -int appointment_id
        -int doctor_id
        -int patient_id
        -string notes
        -int created_by_user_id
        +addMedicine()
    }
    
    class Medicine {
        -int medicine_id
        -string name
        -string dose
        -string description
    }
    
    class Prescription_Medicine {
        -int pm_id
        -int prescription_id
        -int medicine_id
        -int quantity
        -string duration
        -string frequency
        -string notes
    }
    
    class Medical_Record {
        -int record_id
        -int patient_id
        -int doctor_id
        -int appointment_id
        -string description
        -string diagnosis
        -int created_by_user_id
        -datetime updated_at
        +updateRecord()
    }
    
    class Payment {
        -int payment_id
        -int appointment_id
        -double amount
        -string payment_method
        -int paid_by_user_id
        -datetime payment_date
        -string status
        +makePayment()
    }
    
    %% Relationships
    User "1" --> "1" Patient 
    User "1" --> "1" Doctor 
    User "1" --> "1" Receptionist 
    
    Patient "1" --> "0..*" Appointment 
    Doctor "1" --> "0..*" Appointment 
    Receptionist "1" --> "0..*" Appointment 
    
    Appointment "1" --> "0..*" Prescription 
    Appointment "1" --> "0..1" Payment 
    Appointment "1" --> "0..*" Medical_Record 
    
    Doctor "1" --> "0..*" Prescription 
    Doctor "1" --> "0..*" Medical_Record
    
    Patient "1" --> "0..*" Medical_Record 
    
    Prescription "1" --> "0..*" Prescription_Medicine 
    Medicine "1" --> "0..*" Prescription_Medicine 
```

## Relationships Summary

### User Inheritance
- **User** is the base class for Patient, Doctor, and Receptionist
- Each role inherits user authentication and profile information

### Appointment Flow
- **Patient** books appointments (1 to many)
- **Doctor** attends appointments (1 to many)
- **Receptionist** approves appointments (1 to many)

### Medical Documentation
- **Appointment** generates prescriptions (1 to many)
- **Doctor** writes prescriptions (1 to many)
- **Prescription** contains medicines through Prescription_Medicine junction table
- **Medical_Record** tracks patient history linked to appointments

### Payment System
- **Appointment** requires payment (1 to 0..1)
- **Payment** tracks financial transactions

### Many-to-Many Relationship
- **Prescription** and **Medicine** have a many-to-many relationship through **Prescription_Medicine**
- This allows multiple medicines per prescription with specific dosage details

