# Backend API Design Documentation

## API Response Structure

All API responses follow a consistent structure:

```json
{
  "status": "success" | "error",
  "message": "Human-readable message",
  "data": {
    // Response data here
  }
}
```

## Endpoints

### 1. Dashboard Summary
**GET** `/api/dashboard`

**Response:**
```json
{
  "status": "success",
  "message": "Dashboard data fetched successfully",
  "data": {
    "summary": {
      "totalRooms": 6,
      "occupiedRooms": 4,
      "vacantRooms": 1,
      "maintenanceRooms": 1,
      "totalTenants": 4,
      "activeTenants": 4,
      "totalRevenue": 45000,
      "pendingRevenue": 32000,
      "pendingComplaints": 2,
      "overduePayments": 1
    },
    "recentActivity": [...],
    "monthlyRevenue": [45000, 52000, 48000, 55000, 60000, 58000],
    "upcomingPayments": [...]
  }
}
```

### 2. Rooms
**GET** `/api/rooms`

**Response:**
```json
{
  "status": "success",
  "message": "Rooms fetched successfully",
  "data": {
    "rooms": [...],
    "total": 6,
    "occupied": 4,
    "vacant": 1,
    "maintenance": 1
  }
}
```

**GET** `/api/rooms/:id`

**POST** `/api/rooms` - Create new room
**PUT** `/api/rooms/:id` - Update room
**DELETE** `/api/rooms/:id` - Delete room

### 3. Tenants
**GET** `/api/tenants`

**Response:**
```json
{
  "status": "success",
  "message": "Tenants fetched successfully",
  "data": {
    "tenants": [...],
    "total": 4,
    "active": 4,
    "inactive": 0
  }
}
```

**GET** `/api/tenants/:id`
**POST** `/api/tenants`
**PUT** `/api/tenants/:id`
**DELETE** `/api/tenants/:id`

### 4. Complaints
**GET** `/api/complaints`

**Response:**
```json
{
  "status": "success",
  "message": "Complaints fetched successfully",
  "data": {
    "complaints": [...],
    "total": 4,
    "pending": 2,
    "in_progress": 1,
    "resolved": 1
  }
}
```

**GET** `/api/complaints/:id`
**POST** `/api/complaints`
**PUT** `/api/complaints/:id`
**PATCH** `/api/complaints/:id/status` - Update status

### 5. Payments
**GET** `/api/payments`

**Response:**
```json
{
  "status": "success",
  "message": "Payments fetched successfully",
  "data": {
    "payments": [...],
    "total": 4,
    "paid": 2,
    "pending": 1,
    "overdue": 1,
    "totalAmount": 59000,
    "paidAmount": 27000,
    "pendingAmount": 14000,
    "overdueAmount": 18000
  }
}
```

**GET** `/api/payments/:id`
**POST** `/api/payments`
**PUT** `/api/payments/:id`

## Data Models

### Room Model
- id: string
- number: string
- type: "tenant" | "paying_guest"
- status: "occupied" | "vacant" | "maintenance"
- tenantId: string | null
- rent: number
- capacity: number
- currentOccupancy: number
- amenities: string[]
- images: string[]
- description: string | null
- floor: number | null
- area: string | null

### Tenant Model
- id: string
- name: string
- phone: string
- email: string
- roomNumber: string
- moveInDate: ISO 8601 date string
- monthlyRent: number
- type: "tenant" | "paying_guest"
- isActive: boolean
- aadharNumber: string | null
- emergencyContact: string | null
- occupation: string | null
- profileImage: string | null

### Complaint Model
- id: string
- title: string
- description: string
- roomNumber: string
- tenantId: string
- tenantName: string
- status: "pending" | "in_progress" | "resolved"
- priority: "low" | "medium" | "high" | "urgent"
- category: string | null
- createdAt: ISO 8601 datetime
- updatedAt: ISO 8601 datetime
- resolvedAt: ISO 8601 datetime | null
- assignedTo: string | null
- images: string[]

### Payment Model
- id: string
- tenantId: string
- tenantName: string
- roomNumber: string
- amount: number
- dueDate: ISO 8601 date string
- paidDate: ISO 8601 date string | null
- status: "pending" | "paid" | "overdue"
- paymentMethod: "cash" | "online" | "cheque" | null
- transactionId: string | null
- month: string
- year: number
- lateFee: number
- notes: string | null

## Error Response Format

```json
{
  "status": "error",
  "message": "Error description",
  "error": {
    "code": "ERROR_CODE",
    "details": {}
  }
}
```

## Authentication

All endpoints require authentication header:
```
Authorization: Bearer <token>
```

## Pagination (for list endpoints)

Query parameters:
- `page`: number (default: 1)
- `limit`: number (default: 20)
- `sort`: string (default: "createdAt")
- `order`: "asc" | "desc" (default: "desc")

Response includes:
```json
{
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "totalPages": 5
    }
  }
}
```

## Filtering & Search

Query parameters:
- `search`: string (searches in relevant fields)
- `status`: string (filter by status)
- `type`: string (filter by type)
- `dateFrom`: ISO 8601 date
- `dateTo`: ISO 8601 date

