# Flutter App Update: Advertisements + Booking Overhaul

## Context

The backend API (`Vercel-Express-API`) has been updated with:
1. **New Advertisements API** — Full CRUD for bilingual restaurant ads with Stripe checkout payment
2. **Booking API overhaul** — Status values changed (`confirmed` → `accepted`, added `declined`), payment fields removed from bookings, new enriched response fields (`diner`, `restaurant`), new restaurant-specific endpoint path, decline message support, and stricter status transition rules

The Ionic PWA has already been updated. This plan brings the Flutter Android app in line with the new API, following the project's established patterns (Provider/ChangeNotifier, bilingual support, theme awareness, detailed inline comments).

**Key difference**: The Ionic app uses browser redirects for Stripe checkout. The Flutter app will use `url_launcher` (already a dependency) to open Stripe hosted checkout in a Chrome Custom Tab, with session persistence via `SharedPreferences`.

**Design**: All new pages and widgets must use native Android Material Design 3 components (AppBar, TextFormField with OutlineInputBorder, ElevatedButton, Card, etc.) — no custom UI frameworks. Use `Theme.of(context).colorScheme.*` for all colours.

---

## Files to Create (3 new files)

| # | File | Purpose |
|---|------|---------|
| 1 | `lib/models/advertisement.dart` | Advertisement data model |
| 2 | `lib/services/advertisement_service.dart` | Advertisement CRUD + Stripe checkout service |
| 3 | `lib/pages/store_ad_form_page.dart` | Full-screen bilingual ad creation/edit page (Material Design) |

## Files to Modify (12 existing files)

| # | File | Change Summary |
|---|------|----------------|
| 5 | `lib/models/booking.dart` | Remove payment fields, add `declineMessage`/`diner`, change status values |
| 6 | `lib/services/booking_service.dart` | New endpoint path, new methods, remove payment params |
| 7 | `lib/pages/store_bookings_page.dart` | `accepted`/`declined` statuses, decline message dialog, diner info display |
| 8 | `lib/pages/bookings_page.dart` | Update for new model (no payment fields) |
| 9 | `lib/pages/store_page.dart` | Add bottom TabBar (Dashboard / Advertisements tabs), fix booking stat TODO |
| 10 | `lib/pages/home_page.dart` | Add "Featured Offers" section using OfferCarousel with ads from API |
| 11 | `lib/widgets/booking/booking_card.dart` | Remove payment badge, add `accepted`/`declined`, show decline message |
| 12 | `lib/widgets/booking/booking_list.dart` | Minor update for new model compatibility |
| 13 | `lib/models.dart` | Add advertisement model export |
| 14 | `lib/main.dart` | Register AdvertisementService provider |
| 15 | `lib/widgets/booking/booking_form.dart` | No payment references (already clean, verify only) |
| 16 | `CLAUDE.md` | Document new features and changes |

---

## Step-by-Step Implementation

### Step 1: Update Booking Model (`lib/models/booking.dart`)

**Remove:**
- `paymentStatus` field and all references
- `paymentIntentId` field and all references
- `userName` field (replaced by enriched `diner` object)

**Add:**
- `declineMessage` (String?) — reason when restaurant owner declines
- `diner` (BookingDiner?) — enriched contact info from `/restaurant/:id` endpoint
  - `displayName`, `email`, `phoneNumber` (all String?)
- `restaurant` (Map<String, dynamic>?) — enriched restaurant data from user bookings

**Update status comments:** `pending` / `accepted` / `declined` / `completed` / `cancelled`

**Update `fromJson`/`toJson`** accordingly.

**Create `BookingDiner` helper class** within the same file for the enriched diner info.

### Step 2: Update Booking Service (`lib/services/booking_service.dart`)

**Endpoint changes:**
- `getRestaurantBookings`: Change from `GET /API/Bookings?restaurantId=X` → `GET /API/Bookings/restaurant/X`
- `getUserBookings`: Keep `GET /API/Bookings` (no query params needed — API auto-filters by auth token)

**Method signature changes:**
- `updateBooking()`: Remove `paymentStatus`, `paymentIntentId` params. Add `declineMessage`, `dateTime`, `numberOfGuests`, `specialRequests` params.
- `createBooking()`: Remove `paymentStatus` from request body

**New methods:**
- `acceptBooking(String id)` → calls `updateBooking(id, status: 'accepted')`
- `declineBooking(String id, {String? message})` → calls `updateBooking(id, status: 'declined', declineMessage: message)`
- `deleteBooking(String id)` → `DELETE /API/Bookings/:id` (only 30+ day old bookings)

**Rename:** `cancelBooking` stays the same (sets status to `cancelled`)
**Remove:** `completeBooking` is fine — keep it, just verify it works with new API

### Step 3: Create Advertisement Model (`lib/models/advertisement.dart`)

Fields matching API:
- `id` (String)
- `titleEn` / `titleTc` (String?) — maps to `Title_EN` / `Title_TC`
- `contentEn` / `contentTc` (String?) — maps to `Content_EN` / `Content_TC`
- `imageEn` / `imageTc` (String?) — maps to `Image_EN` / `Image_TC`
- `restaurantId` (String)
- `userId` (String?)
- `status` (String) — `active` or `inactive`
- `createdAt` / `modifiedAt` (DateTime?)

Include `fromJson`/`toJson` with snake_case field mapping.

### Step 4: Create Advertisement Service (`lib/services/advertisement_service.dart`)

Extends `ChangeNotifier`, depends on `AuthService`.

**State:**
- `_advertisements` (List<Advertisement>)
- `_isLoading` (bool)
- `_errorMessage` (String?)

**Methods:**
- `getAdvertisements({String? restaurantId})` — `GET /API/Advertisements?restaurantId=X`
- `getAdvertisement(String id)` — `GET /API/Advertisements/:id`
- `createAdvertisement(CreateAdvertisementRequest data)` — `POST /API/Advertisements`
- `updateAdvertisement(String id, Map<String, dynamic> updates)` — `PUT /API/Advertisements/:id`
- `deleteAdvertisement(String id)` — `DELETE /API/Advertisements/:id`
- `createAdCheckoutSession(String restaurantId)` — `POST /API/Stripe/create-ad-checkout-session`
  - Returns `{sessionId, url}`
  - Uses `url_launcher` to open Stripe checkout URL
  - Stores `sessionId` + timestamp in SharedPreferences (`pendingAdSession`)
- `checkPendingSession()` — checks SharedPreferences for unexpired session (2hr TTL)
- `clearPendingSession()` — removes stored session

**Helper class:** `CreateAdvertisementRequest` with restaurantId, titles, contents, images.

### Step 5: Update Store Bookings Page (`lib/pages/store_bookings_page.dart`)

**Status changes:**
- Filter chips: Replace `confirmed` → `accepted`, add `declined`
- `_confirmBooking` → calls `acceptBooking` (status `accepted`)
- `_rejectBooking` → shows dialog with **TextFormField for decline message** → calls `declineBooking(id, message: msg)`
- Status colours: Add `accepted` (blue) and `declined` (red/orange)
- Status labels: Add bilingual for `accepted` (已接受) and `declined` (已拒絕)

**Diner info display:**
- Show `booking.diner?.displayName`, `booking.diner?.email`, `booking.diner?.phoneNumber` in booking cards
- Replace `booking.userName` references with `booking.diner?.displayName`

**Decline message display:**
- When status is `declined` and `declineMessage` is not null, show decline reason

**Mark complete transition:**
- Only allowed from `accepted` status (not from `confirmed` — update the condition)

### Step 6: Update Bookings Page (`lib/pages/bookings_page.dart`)

- Remove any payment-related references
- Update `_canCancel` logic: only `pending` status (not `accepted`)
- Show `declineMessage` for declined bookings
- Show `accepted` status label/colour

### Step 7: Update Booking Card Widget (`lib/widgets/booking/booking_card.dart`)

- **Remove** entire payment status badge section (Container with payment icon)
- **Remove** `_getPaymentStatusLabel` method
- **Update** `_getStatusColor`: add `accepted` (blue), `declined` (red/orange)
- **Update** `_getStatusLabel`: add bilingual for `accepted`/`declined`
- **Update** `_canCancel`: only `pending` status (previously also allowed `confirmed`)
- **Add** decline message display section (similar to special requests)

### Step 8: Update Booking List Widget (`lib/widgets/booking/booking_list.dart`)

- Verify compatibility with updated Booking model (should work with minimal changes)

### Step 9: (Merged into Step 11 — see Store Page)

### Step 10: Create Ad Form Page (`lib/pages/store_ad_form_page.dart`)

Full-screen Material Design page for creating/editing advertisement content:
- **Scaffold** with AppBar (title: "Create Advertisement" / "建立廣告", or "Edit Advertisement" / "編輯廣告")
- **Form fields**: Title EN/TC, Content EN/TC (with character limits: title 100, content 500)
- **Image upload**: EN and TC images via `ImageService` (upload to `Advertisements` folder)
- **Language fallback**: If one language empty, copy from other before submission
- **Validation**: At least one title required
- **Submit**: AppBar save action or bottom button → calls `createAdvertisement()` → pops back with result
- **Native Android look**: Use Material 3 `TextFormField` with `OutlineInputBorder`, standard `AppBar`, `ElevatedButton`
- Navigated to via `Navigator.push()` from `StoreAdsPage`, returns result via `Navigator.pop()`

### Step 11: Update Store Page (`lib/pages/store_page.dart`)

Restructure to use a `DefaultTabController` with a **bottom TabBar** (two tabs):

**Tab 1 — Dashboard** (current scrollable content):
- Restaurant header card
- Quick Actions grid (remove the now-redundant Advertisements card since ads are in Tab 2)
- QR code section
- Statistics section
- **Fix TODO**: Replace hardcoded `'0'` booking count with actual count from `BookingService.getRestaurantBookings()`

**Tab 2 — Advertisements** (inline, no separate page):
- "HK$10 per advertisement" info banner with "Place New Ad" FAB/button
- Ad list: Cards showing bilingual content, image preview, status badge
- Ad card actions: Toggle active/inactive, delete with confirmation
- Stripe payment flow:
  1. Tap "Place New Ad" → call `createAdCheckoutSession(restaurantId)`
  2. Open Stripe checkout URL via `url_launcher`
  3. On return to tab, check `pendingAdSession` → navigate to `StoreAdFormPage`
- Check pending session in `initState` (via `addPostFrameCallback`) and when tab becomes visible
- Empty state: "No advertisements yet"
- Pull-to-refresh
- Full bilingual support (EN/TC)

**Tab bar styling**: Use `TabBar` positioned at the **bottom** of the Scaffold body using `Column` layout (not `AppBar.bottom`), so the tabs sit above the app's bottom navigation. Use `Icons.dashboard` and `Icons.campaign` as tab icons.

### Step 12: Update Home Page (`lib/pages/home_page.dart`)

Add a "Featured Offers" section that displays active advertisements from the API:
- Fetch active ads via `AdvertisementService.getAdvertisements()` on page init
- Map `Advertisement` objects to existing `OfferItem` model (from `offer_carousel.dart`)
  - `imageUrl`: Use `imageEn` or `imageTc` based on language
  - `title`: Use `titleEn` or `titleTc` based on language
  - `subtitle`: Use `contentEn` or `contentTc` based on language
  - `onTap`: Navigate to restaurant detail page using `restaurantId`
- Display using existing `OfferCarousel` widget (already supports auto-play, indicators, etc.)
- Place section between the hero carousel and featured restaurants section
- Show section only when ads are available (hide if empty)
- Section header: "Featured Offers" / "精選優惠"
- Use `FutureBuilder` with future initialized in `initState` to avoid setState during build

### Step 13: Register Provider (`lib/main.dart`)

Add `AdvertisementService` as a `ChangeNotifierProxyProvider<AuthService, AdvertisementService>`:
```dart
ChangeNotifierProxyProvider<AuthService, AdvertisementService>(
  create: (context) => AdvertisementService(context.read<AuthService>()),
  update: (_, authService, previous) => previous ?? AdvertisementService(authService),
),
```

### Step 14: Update Barrel Export (`lib/models.dart`)

Add: `export 'models/advertisement.dart';`

### Step 15: Update CLAUDE.md

- Add AdvertisementService to services list
- Add Advertisement model to models list
- Add StoreAdsPage and StoreAdFormPage to pages list
- Document booking status change (`confirmed` → `accepted`, new `declined`)
- Document removal of payment fields from bookings
- Document Stripe checkout flow for advertisements
- Update file counts and statistics
- Add Phase 6 changelog entry

---

## Verification

1. **Build check**: `flutter analyze` — no lint errors
2. **Booking flow** (diner):
   - Create booking → verify `pending` status, no payment fields sent
   - View bookings → verify no payment badge shown
   - Cancel booking → verify only `pending` bookings can be cancelled
   - View declined booking → verify decline message is displayed
3. **Booking flow** (restaurant owner):
   - View restaurant bookings → verify diner info displayed (name, email, phone)
   - Accept booking → verify status changes to `accepted`
   - Decline booking → verify decline message dialog appears, status changes to `declined`
   - Mark accepted booking as completed → verify transition works
   - Filter by `accepted` and `declined` tabs
4. **Advertisement flow**:
   - View ads list (empty state)
   - Tap "Place New Ad" → verify Stripe checkout URL opens
   - After payment, verify ad form appears
   - Fill bilingual content → submit → verify ad appears in list
   - Toggle ad status (active/inactive)
   - Delete ad with confirmation
5. **Store dashboard**: Verify Advertisements quick action card navigates correctly, booking stat shows real count
6. **Home page ads**: Verify "Featured Offers" section appears when active ads exist, hides when empty, shows correct language content, navigates to restaurant on tap
