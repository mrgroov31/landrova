# Understanding Dashboard Metrics

## 📊 Key Metrics Explained

### 1. **Total Rooms** 🏠
- **What it counts:** Total number of rooms in the building
- **Example:** If you have 6 rooms, this shows **6**

### 2. **Occupied Rooms** ✅
- **What it counts:** Number of rooms that are currently occupied (have at least 1 tenant)
- **Example:** If 4 out of 6 rooms are occupied, this shows **4**
- **Note:** This counts ROOMS, not people

### 3. **Active Tenants** 👥
- **What it counts:** Total number of PEOPLE living in occupied rooms
- **How it's calculated:** Sum of `currentOccupancy` from all occupied rooms
- **Example:** 
  - Room 101: 1 person → contributes 1
  - Room 102 (PG): 2 people → contributes 2
  - Room 201: 1 person → contributes 1
  - **Total Active Tenants = 4**

---

## 🔍 When Can They Be the Same?

### ✅ **Same Number Scenario:**
```
Total Rooms: 6
Occupied Rooms: 4
Active Tenants: 4

This happens when:
- Each occupied room has exactly 1 tenant
- No PG rooms with multiple tenants
- All rented/leased rooms are single occupancy
```

**Example:**
- Room 101 (Rented): 1 tenant
- Room 201 (Rented): 1 tenant  
- Room 301 (Leased): 1 tenant
- Room 401 (Rented): 1 tenant
- **Result:** 4 occupied rooms = 4 active tenants ✅

---

## 🔄 When They're Different

### 📈 **Active Tenants > Occupied Rooms:**
```
Total Rooms: 6
Occupied Rooms: 4
Active Tenants: 8

This happens when:
- PG rooms have multiple tenants
- Shared rooms with 2+ people
```

**Example:**
- Room 101 (Rented): 1 tenant
- Room 102 (PG, capacity 3): 3 tenants ← Multiple people!
- Room 201 (Rented): 1 tenant
- Room 202 (PG, capacity 2): 2 tenants ← Multiple people!
- Room 301 (Vacant): 0 tenants
- Room 302 (Maintenance): 0 tenants
- **Result:** 4 occupied rooms, but 7 active tenants (1+3+1+2)

### 📉 **Active Tenants < Occupied Rooms:**
```
This is rare but can happen if:
- Room is marked as "occupied" but currentOccupancy is 0
- Data inconsistency
- Room is transitioning (tenant moving out)
```

---

## 💡 Real-World Examples

### Example 1: Mixed Building
```
Building: Sunshine Apartments
- 2 Rented Rooms (1 person each)
- 2 PG Rooms (3 people each)
- 2 Vacant Rooms

Metrics:
- Total Rooms: 6
- Occupied Rooms: 4 (2 rented + 2 PG)
- Active Tenants: 8 (2 + 6)
```

### Example 2: All Single Occupancy
```
Building: Green Valley
- 4 Rented Rooms (1 person each)
- 2 Vacant Rooms

Metrics:
- Total Rooms: 6
- Occupied Rooms: 4
- Active Tenants: 4 (same as occupied!)
```

### Example 3: PG Heavy Building
```
Building: Student PG
- 1 Rented Room (1 person)
- 5 PG Rooms (4 people each)

Metrics:
- Total Rooms: 6
- Occupied Rooms: 6
- Active Tenants: 21 (1 + 20)
```

---

## 🎯 Why This Matters

### For Property Owners:

1. **Occupied Rooms** tells you:
   - How many rooms are generating rent
   - Occupancy rate: `(Occupied / Total) × 100%`
   - Available rooms for new tenants

2. **Active Tenants** tells you:
   - Total number of people to manage
   - Maintenance load (more people = more wear)
   - Utility usage estimation
   - Communication needs

3. **The Difference** tells you:
   - If you have shared/PG rooms
   - Average occupancy per room
   - Revenue potential (more tenants = more rent)

---

## 📐 Calculation Formula

### Current Implementation:
```dart
// Occupied Rooms = Count of rooms with status 'occupied'
Occupied Rooms = rooms.where(r => r.status == 'occupied').length

// Active Tenants = Sum of currentOccupancy from occupied rooms
Active Tenants = rooms
  .where(r => r.status == 'occupied')
  .sum(r => r.currentOccupancy)
```

### Occupancy Rate:
```
Occupancy Rate = (Occupied Rooms / Total Rooms) × 100%
```

### Average Tenants per Room:
```
Avg Tenants/Room = Active Tenants / Occupied Rooms
```

---

## 🔧 How It Works in the App

### Room Model:
```dart
class Room {
  final int capacity;        // Maximum people (e.g., 3 for PG)
  final int currentOccupancy; // Current people (e.g., 2)
  final String status;        // 'occupied', 'vacant', 'maintenance'
}
```

### Example Room:
```json
{
  "id": "2",
  "number": "102",
  "type": "pg",
  "status": "occupied",
  "capacity": 3,
  "currentOccupancy": 2  ← 2 people currently living here
}
```

This room:
- ✅ Counts as **1** occupied room
- ✅ Contributes **2** to active tenants

---

## ✅ Summary

| Metric | Counts | Can Match? |
|--------|--------|------------|
| **Total Rooms** | All rooms | - |
| **Occupied Rooms** | Rooms with tenants | ✅ Yes, if all rooms have 1 tenant each |
| **Active Tenants** | Total people | ✅ Yes, if all rooms have 1 tenant each |

**They match when:** Every occupied room has exactly 1 tenant  
**They differ when:** PG rooms or shared rooms have multiple tenants

---

## 💼 Business Insight

- **High Occupied Rooms, Low Active Tenants** = Mostly single-occupancy rooms
- **High Occupied Rooms, High Active Tenants** = Many shared/PG rooms
- **Low Occupied Rooms, High Active Tenants** = Few rooms but packed with people

This helps you understand your property's occupancy pattern! 🎯

