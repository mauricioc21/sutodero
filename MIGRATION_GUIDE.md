# InventoryService Firestore Migration Guide

## Overview

The `InventoryService` has been completely migrated from **Hive (local storage)** to **Firestore (cloud storage)** to fix the critical data persistence issue where user data was being lost.

## What Changed

### Before (Hive - Local Storage)
```dart
// Data stored locally per device
await inventoryService.getAllProperties();
await inventoryService.createProperty(...);
```

### After (Firestore - Cloud Storage)
```dart
// Data stored in cloud per user
await inventoryService.getAllProperties(userId);
await inventoryService.createProperty(userId: userId, ...);
```

## Data Structure in Firestore

```
firestore/
  └── users/
      └── {userId}/
          └── properties/
              └── {propertyId}/
                  ├── (property data)
                  └── rooms/
                      └── {roomId}/
                          └── (room data)
```

## Required Changes in All Screens

### 1. Import Provider and AuthService

```dart
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
```

### 2. Get userId from AuthService

```dart
// In your methods that call InventoryService:
final authService = Provider.of<AuthService>(context, listen: false);
final userId = authService.currentUser?.uid;

if (userId == null) {
  // Handle not logged in
  return;
}
```

### 3. Update All InventoryService Calls

| Old Call | New Call |
|----------|----------|
| `getAllProperties()` | `getAllProperties(userId)` |
| `getProperty(id)` | `getProperty(userId, propertyId)` |
| `saveProperty(property)` | `saveProperty(userId, property)` |
| `createProperty(...)` | `createProperty(userId: userId, ...)` |
| `updateProperty(property)` | `updateProperty(userId, property)` |
| `deleteProperty(propertyId)` | `deleteProperty(userId, propertyId)` |
| `getRoomsByProperty(propertyId)` | `getRoomsByProperty(userId, propertyId)` |
| `getRoom(roomId)` | `getRoom(userId, propertyId, roomId)` |
| `saveRoom(room)` | `saveRoom(userId, propertyId, room)` |
| `createRoom(...)` | `createRoom(userId: userId, propertyId: propertyId, ...)` |
| `updateRoom(room)` | `updateRoom(userId, propertyId, room)` |
| `deleteRoom(roomId)` | `deleteRoom(userId, propertyId, roomId)` |
| `addRoomPhoto(roomId, url)` | `addRoomPhoto(userId, propertyId, roomId, url)` |
| `setRoom360Photo(roomId, url)` | `setRoom360Photo(userId, propertyId, roomId, url)` |
| `addRoomProblem(roomId, text)` | `addRoomProblem(userId, propertyId, roomId, text)` |
| `searchProperties(query)` | `searchProperties(userId, query)` |
| `getStatistics()` | `getStatistics(userId)` |

## Files That Need Updates

### ✅ Already Updated
- `lib/services/inventory_service.dart` - Completely rewritten for Firestore
- `lib/services/activity_log_service.dart` - Enhanced with CRUD logging
- `lib/screens/inventory/inventories_screen.dart` - Updated getAllProperties and searchProperties

### ⏳ Still Need Updates

1. **lib/screens/inventory/property_detail_screen.dart**
   - Line 62: `getRoomsByProperty()` → needs userId
   - Line 756: `deleteProperty()` → needs userId

2. **lib/screens/inventory/room_detail_screen.dart**
   - Line 41: `getRoom()` → needs userId and propertyId
   - Line 72: `getProperty()` → needs userId
   - Line 145, 166: `addRoomPhoto()` → needs userId and propertyId
   - Line 236: `setRoom360Photo()` → needs userId and propertyId
   - Line 357: `deleteRoom()` → needs userId and propertyId

3. **lib/screens/inventory/add_edit_property_screen.dart**
   - Line 121: `updateProperty()` → needs userId
   - Line 143: `createProperty()` → needs userId parameter

4. **lib/screens/inventory/add_edit_room_screen.dart**
   - Line 656, 680: `updateRoom()` → needs userId and propertyId
   - Line 659: `createRoom()` → needs userId and propertyId parameters

## Example: Updating a Screen

### Before
```dart
class PropertyDetailScreen extends StatefulWidget {
  final InventoryProperty property;
  // ...
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final InventoryService _inventoryService = InventoryService();
  
  Future<void> _loadRooms() async {
    final rooms = await _inventoryService.getRoomsByProperty(widget.property.id);
    // ...
  }
  
  Future<void> _deleteProperty() async {
    await _inventoryService.deleteProperty(widget.property.id);
    // ...
  }
}
```

### After
```dart
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class PropertyDetailScreen extends StatefulWidget {
  final InventoryProperty property;
  // ...
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final InventoryService _inventoryService = InventoryService();
  
  String? get _userId => Provider.of<AuthService>(context, listen: false).currentUser?.uid;
  
  Future<void> _loadRooms() async {
    final userId = _userId;
    if (userId == null) return;
    
    final rooms = await _inventoryService.getRoomsByProperty(userId, widget.property.id);
    // ...
  }
  
  Future<void> _deleteProperty() async {
    final userId = _userId;
    if (userId == null) return;
    
    await _inventoryService.deleteProperty(userId, widget.property.id);
    // ...
  }
}
```

## Benefits of This Migration

1. **✅ Data Persistence**: Data survives app uninstall
2. **✅ Multi-Device Sync**: Access your data from any device
3. **✅ Per-User Isolation**: Each user only sees their own data
4. **✅ Cloud Backup**: Data automatically backed up to Firebase
5. **✅ Activity Tracking**: All operations logged for auditing
6. **✅ Scalability**: Ready for thousands of users

## Testing Checklist

After updating each screen, test:

- [ ] Can load data (properties/rooms appear)
- [ ] Can create new items (properties/rooms)
- [ ] Can update items
- [ ] Can delete items
- [ ] Can upload photos
- [ ] No console errors about missing parameters
- [ ] Data persists after app restart
- [ ] Different users see different data

## Need Help?

If you encounter errors like:
```
The argument type 'String' can't be assigned to the parameter type 'String?'
```

You're missing the `userId` parameter. Add it using the pattern shown above.
