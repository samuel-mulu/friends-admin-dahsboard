# KISS Bulk Registration Simplification

## Summary

Simplified bulk cartela selection from complex reservation-during-selection to simple local-only selection until final registration.

---

## What Changed

### Before (Complex)
```
User taps cartela in select mode
  ↓
Add to _selectedCartelaIds
Add to _pendingBulkReserveIds
  ↓
Schedule debounced reserve (150ms)
  ↓
_flushBulkReserve calls reserveCartelasBulk API
  ↓
Server creates reservation holds
  ↓
Store in _selectionReservations
Apply RESERVED_ME patches
  ↓
Generation guards
Late response cleanup
Expiry timers
Server cancellation on deselect
  ↓
Review sheet requires reservations
  ↓
Register confirms reservations
```

### After (KISS)
```
User taps cartela in select mode
  ↓
Add/remove from _selectedCartelaIds (local only)
setState()
  ↓
Review sheet shows selected cartelas
  ↓
Register calls registerCartelasBulk with selected IDs
  ↓
Backend checks availability in transaction
Backend registers or returns conflicts
  ↓
Success: Clear selected cartelas
Failure: Remove conflicted cartelas, show message
```

---

## Code Changes

### 1. Selection (lines 877-900)
**Before:**
- Called `_unselectReservedCartela` for deselection
- Added to `_pendingBulkReserveIds`
- Called `_scheduleBulkReserve`
- Applied RESERVED_ME patches

**After:**
```dart
// Simple local add/remove
setState(() {
  _selectedCartelaIds.add/remove(cartelaId);
  _selectedCartelaNumbers[cartelaId] = number;
});
```

### 2. Clear Selection (lines 903-913)
**Before:**
- Called `_resetBulkSelectionState`
- Released server holds
- Applied AVAILABLE patches

**After:**
```dart
setState(() {
  _selectedCartelaIds.clear();
  _selectedCartelaNumbers.clear();
});
```

### 3. Auto-Open Reserve (lines 915-922)
**Before:**
- Called `_flushBulkReserve(forceAllSelected: true)`

**After:**
```dart
// Just select locally, no reserve calls
for (final option in options) {
  await _toggleCartelaSelection(option);
}
```

### 4. Bulk Register (lines 1165-1177)
**Before:**
- Called `await _flushBulkReserve(forceAllSelected: true)`
- Checked `_selectionReservations` for holds
- Returned failure if holds missing

**After:**
```dart
// No flush reserve, no hold checks
_bulkDebugLog('bulk_register_start count=${cartelas.length}');
// Just register selected cartelas
```

### 5. Register Success (lines 1207-1219)
**Before:**
- Called `_forgetSelectionReservations`

**After:**
```dart
// Just clear selected state
setState(() {
  for (final success in result.successes) {
    _selectedCartelaIds.remove(success.cartelaId);
    _selectedCartelaNumbers.remove(success.cartelaId);
  }
});
```

### 6. Register Failure (lines 1221-1244)
**Before:**
- Only showed message and refreshed state

**After:**
```dart
// Remove conflicted cartelas from selection
setState(() {
  for (final failure in result.failures) {
    _selectedCartelaIds.remove(failure.cartelaId);
    _selectedCartelaNumbers.remove(failure.cartelaId);
  }
});
// Show message and refresh
```

### 7. Select Mode Exit (lines 549-558)
**Before:**
- Called `_resetBulkSelectionState(releaseHolds: true, applyAvailablePatches: true)`

**After:**
```dart
setState(() {
  _selectModeEnabled = false;
  _selectedCartelaIds.clear();
  _selectedCartelaNumbers.clear();
});
```

### 8. Review Sheet Open (lines 1065-1075)
**Before:**
- Called `await _flushBulkReserve(forceAllSelected: true)`
- Checked if selection empty after flush

**After:**
```dart
// Check if selection empty first
if (_selectedCartelaIds.isEmpty) {
  // Show message, don't open sheet
  return;
}
// Open sheet directly
```

### 9. Review Sheet Close (lines 1128-1137)
**Before:**
- Bumped generation
- Cancelled timers
- Cleared pending IDs
- Cleared reservations

**After:**
```dart
setState(() {
  _reviewSheetOpen = false;
  if (confirmed == true) {
    _selectModeEnabled = false;
    _selectedCartelaIds.clear();
    _selectedCartelaNumbers.clear();
  }
});
```

---

## Removed Complexity

### State Variables (Now Unused)
- `_pendingBulkReserveIds` - tracked IDs waiting for reserve
- `_selectionReservations` - stored server reservation holds
- `_bulkReserveDebounceTimer` - debounced reserve calls
- `_bulkReserveGeneration` - guarded late responses
- `_bulkReserveInFlight` - prevented concurrent reserves

### Methods (Now Unused)
- `_scheduleBulkReserve()` - debounced reserve scheduling
- `_flushBulkReserve()` - complex reserve API call with guards
- `_unselectReservedCartela()` - deselection with server cancel
- `_resetBulkSelectionState()` - complex cleanup with server calls
- `_forgetSelectionReservations()` - reservation cleanup
- `_takeExpiredSelectionReservationIds()` - expiry handling
- `_bumpBulkReserveGeneration()` - generation increment

### API Calls (No Longer Made During Selection)
- `reserveCartelasBulk` - bulk reservation
- `cancelReservation` - reservation cancellation

### Patch Updates (No Longer Applied)
- `RESERVED_ME` patches for local selection
- `AVAILABLE` patches for local deselection

---

## Benefits

### 1. Simpler Mental Model
- Selection is just local UI state
- No hidden server state during selection
- Registration is one atomic backend call

### 2. No Ghost Reserved States
- No late reserve responses
- No stale reservation patches
- No generation guard races
- No timer cleanup issues

### 3. Fewer Moving Parts
- No debounce timers
- No generation guards
- No reservation expiry
- No server hold management

### 4. Better Conflict Handling
- Backend enforces uniqueness in transaction
- UI shows clear conflict messages
- Failed cartelas removed from selection
- User can immediately select alternatives

### 5. Easier to Understand
- Code flow is linear
- No async coordination
- No complex state machines
- Easier to debug and maintain

---

## Product Behavior

### Single Mode (Unchanged)
```
Tap cartela → Modal opens → Reserve → Confirm → Register
```

### Bulk Mode (Simplified)
```
Enter select mode → Tap cartelas (local only) → Review → Register (one API call)
```

### Conflict Handling
```
Backend returns conflicts → Remove from selection → Show message → User selects others
```

---

## Testing

### Manual Testing Scenarios
1. ✅ Select 3 cartelas → all show selected (not reserved)
2. ✅ Deselect 1 → immediately removed from selection
3. ✅ Exit select mode → all selections cleared
4. ✅ Review sheet → shows selected cartelas
5. ✅ Register success → selections cleared, cartelas registered
6. ✅ Register conflict → conflicted removed, message shown
7. ✅ No ghost reserved states after any operation
8. ✅ Normal/Bonus/Big Game all work the same

### Debug Logs to Verify
```
[bulk_debug] selected_set after_add=[5,6,7]
[bulk_debug] deselect cartela=5 selected_set=[6,7]
[bulk_debug] bulk_register_start count=2
[bulk_debug] bulk_register_success count=2
```

**Should NOT see:**
```
[bulk_debug] flush_start generation=...
[bulk_debug] apply_reservation cartela=...
[bulk_debug] skip_reservation cartela=...
[bulk_debug] cancel_server_reservation cartela=...
```

---

## Migration Notes

### Unused Code (Can Be Removed Later)
- `_resetBulkSelectionState` (warning: unused_element)
- `_unselectReservedCartela` (no longer called)
- `_scheduleBulkReserve` (no longer called)
- `_flushBulkReserve` (no longer called)
- All reservation-related state variables

### Backend Compatibility
- `registerCartelasBulk` must work without prior reservations
- Backend should check availability in transaction
- Backend should return clear conflict messages
- No changes needed to single-cartela flow

---

## Success Criteria

✅ Bulk selection is purely local until registration  
✅ No server calls during selection/deselection  
✅ No RESERVED_ME patches for local selection  
✅ No ghost reserved states  
✅ One registration API call at confirm  
✅ Clear conflict handling  
✅ Single mode unchanged  
✅ Simpler, more maintainable code  

---

## Next Steps

1. **Test manually** - verify all scenarios work
2. **Monitor logs** - ensure no old reserve calls appear
3. **Remove unused code** - clean up after verification
4. **Update backend** - if needed for reservation-less bulk register
5. **Document** - update product docs with new flow
