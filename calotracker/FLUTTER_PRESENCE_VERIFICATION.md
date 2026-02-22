# Flutter Code Verification - update_presence() Function

## Function Signature

**Database (SQL)**:
```sql
CREATE FUNCTION public.update_presence(p_status TEXT)
RETURNS void
```

**Parameters**:
- `p_status` - Type: `TEXT`
- Valid values: `'online'`, `'offline'`, `'away'`

---

## Flutter Service Code

**File**: [lib/services/presence_service.dart](../lib/services/presence_service.dart)

### Current Implementation ✅ CORRECT

#### Go Online (Line 26):
```dart
await _client.rpc('update_presence', params: {'p_status': 'online'});
```

#### Go Offline (Line 50):
```dart
await _client.rpc('update_presence', params: {'p_status': 'offline'});
```

#### Heartbeat Update (Line 63):
```dart
await _client.rpc('update_presence', params: {'p_status': 'online'});
```

---

## Parameter Matching

| Requirement | SQL Function | Flutter Code | Status |
|-------------|-------------|--------------|--------|
| Function name | `update_presence` | `'update_presence'` | ✅ Match |
| Parameter name | `p_status` | `'p_status'` | ✅ Match |
| Parameter type | `TEXT` | `String` | ✅ Compatible |
| Valid values | `'online'`, `'offline'`, `'away'` | Uses `'online'`, `'offline'` | ✅ Valid |

---

## Error Handling

The Flutter code includes try-catch blocks:

```dart
try {
  await _client.rpc('update_presence', params: {'p_status': 'online'});
  debugPrint('✅ Now online with heartbeat');
} catch (e) {
  debugPrint('❌ Error going online: $e');
}
```

**Good practices**:
- ✅ Wrapped in try-catch
- ✅ Debug logging for both success and error
- ✅ Non-blocking (doesn't crash app if fails)

---

## Function Permissions

**SQL**:
```sql
GRANT EXECUTE ON FUNCTION public.update_presence(text) TO authenticated;
```

This grants all authenticated users permission to call the function.

**Verification**:
```sql
SELECT has_function_privilege('authenticated', 'public.update_presence(text)', 'EXECUTE');
-- Should return: true
```

---

## What the Function Does

1. **Validates input**: Checks that `p_status` is one of: `'online'`, `'offline'`, `'away'`

2. **Updates profiles table**:
   ```sql
   UPDATE public.profiles
   SET
     status = p_status,
     is_online = (p_status = 'online'),
     last_seen = NOW()
   WHERE id = auth.uid();
   ```

3. **Updates user_presence table** (if exists):
   ```sql
   INSERT INTO public.user_presence (user_id, is_online, last_seen)
   VALUES (auth.uid(), (p_status = 'online'), NOW())
   ON CONFLICT (user_id) DO UPDATE
   SET is_online = (p_status = 'online'), last_seen = NOW();
   ```

---

## Security

- ✅ **SECURITY DEFINER**: Function runs with elevated privileges (bypasses RLS)
- ✅ **Uses auth.uid()**: Only updates the calling user's own data
- ✅ **Input validation**: Rejects invalid status values
- ✅ **Scoped permissions**: Only authenticated users can execute

**Security Model**:
```
User authenticates → Calls update_presence
                  → Function checks auth.uid()
                  → Updates ONLY that user's record
                  → No access to other users' data
```

---

## Testing the Function

### 1. Test from SQL Editor (Supabase Dashboard)

```sql
-- Login as a user first, then run:
SELECT public.update_presence('online');
-- Should return: (nothing, void function)

-- Verify the update
SELECT id, username, status, is_online, last_seen
FROM public.profiles
WHERE id = auth.uid();
-- Should show: status='online', is_online=true, last_seen=now
```

### 2. Test from Flutter App

Add debug logging:

```dart
Future<void> goOnline() async {
  if (_userId == null) return;

  try {
    debugPrint('🔍 Calling update_presence with status=online');

    final result = await _client.rpc('update_presence', params: {'p_status': 'online'});

    debugPrint('✅ update_presence succeeded: $result');
  } catch (e) {
    debugPrint('❌ update_presence failed: $e');
    debugPrint('📋 Error type: ${e.runtimeType}');
  }
}
```

**Expected console output**:
```
🔍 Calling update_presence with status=online
✅ update_presence succeeded: null
✅ Now online with heartbeat
```

### 3. Test Error Cases

**Invalid status**:
```dart
await _client.rpc('update_presence', params: {'p_status': 'busy'});
// Should throw: Exception: Invalid status: must be online, offline, or away
```

**Missing parameter**:
```dart
await _client.rpc('update_presence', params: {});
// Should throw: Missing required parameter
```

**Wrong parameter name**:
```dart
await _client.rpc('update_presence', params: {'status': 'online'});
// Should throw: Function update_presence(status) does not exist
```

---

## Common Issues & Solutions

### Issue: "Function not found"

**Error**:
```
PostgrestException(message: Could not find the function public.update_presence(p_status)
in the schema cache, code: PGRST202)
```

**Solution**:
```sql
-- Check if function exists
SELECT proname, prosrc FROM pg_proc WHERE proname = 'update_presence';

-- If not found, run migration 034
```

### Issue: "Permission denied"

**Error**:
```
PostgrestException(message: permission denied for function update_presence, code: 42501)
```

**Solution**:
```sql
-- Grant permission
GRANT EXECUTE ON FUNCTION public.update_presence(text) TO authenticated;
```

### Issue: "Invalid status"

**Error**:
```
Exception: Invalid status: must be online, offline, or away
```

**Solution**:
- Only use: `'online'`, `'offline'`, `'away'`
- Check for typos: `'Online'` ❌ should be `'online'` ✅
- Check for extra spaces: `'online '` ❌ should be `'online'` ✅

---

## Alternative: Using Direct Updates (Without RPC)

If you prefer not to use RPC functions, you can update directly:

```dart
// Alternative approach (but less secure, subject to RLS)
await _client.from('profiles').update({
  'status': 'online',
  'is_online': true,
  'last_seen': DateTime.now().toIso8601String(),
}).eq('id', _userId);
```

**Pros**:
- No RPC function needed
- Simpler to understand

**Cons**:
- Subject to RLS policies (can be blocked)
- Doesn't update user_presence table automatically
- Less atomic (two separate queries)

**Recommendation**: ✅ Use the RPC function (`update_presence`) as it's more robust and secure.

---

## Summary

✅ **Current Flutter Code**: Correctly calls `update_presence('online')` and `update_presence('offline')`

✅ **Parameter Matching**: Function signature matches Flutter RPC call exactly

✅ **Security**: Function is secure and scoped to current user only

✅ **Error Handling**: Proper try-catch blocks in place

✅ **Testing**: Can verify with debug logs and SQL queries

**No changes needed** to Flutter code - it's already correct! Just run the SQL migration to create the function.
