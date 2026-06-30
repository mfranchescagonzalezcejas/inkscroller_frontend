# InkScroller — Data Safety & App Content Declarations

## 1. Data Collection Summary

### Data Types Collected

| Data Type | Collected | Shared | Purpose | Required |
|-----------|-----------|--------|---------|----------|
| **Account info** (email, display name) | ✅ Yes | ✅ Yes (Firebase Auth) | App functionality (authentication) | Yes |
| **Password** | ✅ Yes | ✅ Yes (Firebase Auth) | App functionality (authentication) | Yes |
| **Usage data** (analytics events, screen views) | ✅ Yes | ✅ Yes (Firebase Analytics) | Analytics | No |
| **App interactions** (reading progress, library) | ✅ Yes | ✅ Yes (Backend API) | App functionality | Yes |
| **Device identifiers** (Firebase automatic) | ✅ Yes | ✅ Yes (Firebase) | Analytics, crash reporting | No |

### Data Types NOT Collected

- ❌ Contacts
- ❌ Location (no GPS permission)
- ❌ Camera/Microphone
- ❌ Files/Media (external storage)
- ❌ Health/Fitness
- ❌ Financial info
- ❌ Government IDs
- ❌ Browsing history (external)
- ❌ SMS/Call logs
- ❌ Installed apps

## 2. Data Safety Questions (Play Console)

### Does your app collect or share any required data types?
**Yes** — Account info, Usage data, App interactions

### Is all of the data collected by your app required?
**Yes** — Account info and app interactions are required for core functionality. Usage data (analytics) is optional but collected by default.

### Can users choose whether to share their data?
**Yes** — Users can:
- Create an account without providing any optional data
- Use the app without analytics (Firebase Analytics can be disabled at the OS level)
- Delete their account and all associated data (feature implemented in #17)

### What data does your app collect?
- **Account info**: Email address, display name
- **Usage data**: App interactions, screen views, feature usage
- **App interactions**: Reading progress, library content, manga metadata

### Is this data collected for a legitimate purpose as described?
**Yes** — All data collection is necessary for:
- Authentication (account info)
- Core app functionality (reading progress, library)
- Analytics to improve the app (usage data)

### Does your app share data with third parties?
**Yes** — Data is shared with:
- **Firebase Auth** (Google): Authentication
- **Firebase Analytics** (Google): Analytics
- **Backend API** (devdigi.dev): App functionality

### Does your app have a privacy policy?
**To be created** — Will be hosted at a public URL before release.

### Can users request data deletion?
**Yes** — The app implements account deletion (issue #17, merged). Users can delete their account and all associated data from the Profile page.

## 3. App Content Declarations

### Content Rating
**Target audience**: Teens (13+) and up
**Content descriptors**: 
- Manga/comics content (fictional)
- User-generated content: None
- Social features: None (no user profiles, comments, or sharing)

### Ads
**Does your app contain ads?**
**No** — The app does not display any advertisements.

### Sign-in
**Does your app require sign-in?**
**No** — The app can be used without an account (guest mode). Sign-in is optional for:
- Syncing library across devices
- Saving reading progress to the cloud

### Government IDs
**Does your app request government-issued IDs?**
**No**

### Financial info
**Does your app handle financial information?**
**No** — The app does not process payments or handle financial data.

### Health info
**Does your app handle health information?**
**No**

## 4. Permissions Declaration

| Permission | Used | Justification |
|-----------|------|---------------|
| `INTERNET` | ✅ | Required for API calls, Firebase services, and image loading |

**No other permissions are requested.** The app does not access:
- Camera
- Microphone
- Location
- Contacts
- Storage (external)
- Phone state

## 5. Data Encryption

- **In transit**: All API calls use HTTPS (TLS 1.2+)
- **At rest**: 
  - Firebase Auth encrypts stored credentials
  - SharedPreferences data is stored in app-private storage (not accessible to other apps)
  - Backend data storage encryption is managed server-side

## 6. Account Deletion

Users can delete their account and all associated data:
1. Navigate to Profile → Settings
2. Tap "Delete Account"
3. Type "DELETE" to confirm
4. The following data is permanently removed:
   - Backend account and library data
   - Firebase authentication account
   - All local data on the device (reading progress, library cache, preferences)
   - User is signed out of the application

## 7. Data Retention

| Data Type | Retention Period |
|-----------|-----------------|
| Account info | Until user deletes account |
| Reading progress | Until user deletes account |
| Library data | Until user deletes account |
| Analytics data | 14 months (Firebase default) |
| Local cache | Until app uninstall or user clears data |

## 8. Children's Privacy

**Is this app directed at children under 13?**
**No** — The app is not directed at children under 13. The content (manga/comics) is suitable for teens (13+) and up.

**Does your app knowingly collect personal information from children under 13?**
**No** — The app does not knowingly collect personal information from children under 13. Firebase Auth requires users to be at least 13 years old.

## 9. Compliance Notes

- **COPPA**: App is not directed at children under 13
- **GDPR**: Users can delete their account and data at any time
- **CCPA**: Users can request data deletion via the account deletion feature
- **Play Store Policy**: Compliant with Data Safety requirements
