# Smart Home System - Use Case Diagram

## Complete Use Case Diagram

```mermaid
%%{init: {'theme':'base', 'themeVariables': { 'fontSize':'16px'}}}%%
graph TB
    U((User))
    
    CA[Create account]
    LI[Log in]
    MI[Modify account<br/>information]
    DA[Delete account]
    ATF[Add trusted<br/>face]
    RTF[Remove trusted<br/>face]
    CD[Control doors]
    CL[Control lighting]
    VSR[View sensor<br/>readings]
    MHS[Monitor home<br/>status]
    
    U --> CA
    U --> LI
    U --> MI
    U --> DA
    U --> ATF
    U --> RTF
    U --> CD
    U --> CL
    U --> VSR
    U --> MHS
    
    LI -.->|include| MI
    LI -.->|include| DA
    LI -.->|include| ATF
    LI -.->|include| RTF
    LI -.->|include| CD
    LI -.->|include| CL
    LI -.->|include| VSR
    LI -.->|include| MHS
```

---

## Emergency System Use Cases

```mermaid
%%{init: {'theme':'base', 'themeVariables': { 'fontSize':'16px'}}}%%
graph TB
    ES((Smart Home<br/>Emergency System))
    
    AGLE[Activate gas leakage<br/>emergency protocol]
    AWLE[Activate water leakage<br/>emergency protocol]
    AFE[Activate fire<br/>emergency protocol]
    AIE[Activate intruder<br/>emergency protocol]
    
    ES --> AGLE
    ES --> AWLE
    ES --> AFE
    ES --> AIE
```

## Alternative Compact View

```mermaid
graph LR
    U((User))
    ES((Smart home<br/>emergency system))
    
    subgraph SHS[Smart Home System]
        direction TB
        
        subgraph Account[Account Management]
            CA[Create account]
            LI[Log in]
            MI[Modify account<br/>information]
            DA[Delete account]
        end
        
        subgraph Security[Security & Access]
            ATF[Add trusted face]
            RTF[Remove trusted face]
        end
        
        subgraph Control[Home Control]
            CD[Control doors]
            CL[Control lighting]
        end
        
        subgraph Monitoring[Monitoring]
            VSR[View sensor<br/>readings]
            MHS[Monitor home<br/>status]
        end
        
        subgraph Emergency[Emergency Protocols]
            AGLE[Activate gas leakage<br/>emergency protocol]
            AWLE[Activate water leakage<br/>emergency protocol]
            AFE[Activate fire<br/>emergency protocol]
            AIE[Activate intruder<br/>emergency protocol]
        end
        
        %% Include relationships
        LI -.->|include| MI
        LI -.->|include| DA
        LI -.->|include| ATF
        LI -.->|include| RTF
        LI -.->|include| CD
        LI -.->|include| CL
        LI -.->|include| VSR
        LI -.->|include| MHS
    end
    
    %% User connections
    U --> CA
    U --> LI
    U --> MI
    U --> DA
    U --> ATF
    U --> RTF
    U --> CD
    U --> CL
    U --> VSR
    U --> MHS
    
    %% Emergency system connections
    ES --> AGLE
    ES --> AWLE
    ES --> AFE
    ES --> AIE
```

## Use Cases Summary

### User Actor
The **User** can perform the following actions:

#### Account Management
- **Create account**: Register new user account
- **Log in**: Authenticate to access system
- **Modify account information**: Update user profile
- **Delete account**: Remove user account

#### Security & Access Control
- **Add trusted face**: Register facial recognition
- **Remove trusted face**: Delete facial recognition data

#### Home Control
- **Control doors**: Lock/unlock doors remotely
- **Control lighting**: Turn lights on/off, adjust brightness

#### Monitoring
- **View sensor readings**: Check temperature, humidity, etc.
- **Monitor home status**: Overall system status overview

### Smart Home Emergency System Actor
The **Smart home emergency system** automatically activates emergency protocols:

#### Emergency Protocols
- **Activate gas leakage emergency protocol**: Detect and respond to gas leaks
- **Activate water leakage emergency protocol**: Detect and respond to water leaks
- **Activate fire emergency protocol**: Detect and respond to fire
- **Activate intruder emergency protocol**: Detect and respond to unauthorized access

### Relationships
- All user operations (except Create account) require **Log in** (include relationship)
- Emergency protocols are triggered automatically by the emergency system
