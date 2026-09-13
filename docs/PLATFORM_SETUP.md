# Platform setup

Platform folders are not committed. Run `flutter create .` once, then apply
what follows — these are the entries the plugins need and that store review
asks about.

## Android

`android/app/build.gradle`

```gradle
android {
    compileSdk 35
    defaultConfig {
        applicationId "ht.jwennmet.app"
        minSdk 23            // firebase_auth requires 23+
        targetSdk 35
        multiDexEnabled true
    }
}
```

`android/app/src/main/AndroidManifest.xml` — inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- url_launcher needs these declared to see tel: and mailto: handlers -->
<queries>
  <intent><action android:name="android.intent.action.VIEW"/>
    <data android:scheme="https"/></intent>
  <intent><action android:name="android.intent.action.DIAL"/>
    <data android:scheme="tel"/></intent>
  <intent><action android:name="android.intent.action.SENDTO"/>
    <data android:scheme="mailto"/></intent>
</queries>
```

Inside `<application>`:

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_MAPS_ANDROID_KEY"/>
<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id"
           android:value="jwennmet_default"/>
<meta-data android:name="com.google.firebase.messaging.default_notification_color"
           android:resource="@color/brand_blue"/>
```

`android/app/src/main/res/values/colors.xml`

```xml
<resources><color name="brand_blue">#0A6CFF</color></resources>
```

Google services plugin: add `id 'com.google.gms.google-services'` to
`android/app/build.gradle` and the matching classpath to the project-level
Gradle file (FlutterFire prints the exact lines).

## iOS

`ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Jwenn Mèt uses your location to show skilled workers near you.</string>
<key>NSCameraUsageDescription</key>
<string>Take a photo of your ID or of the job so a worker can quote it.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Attach photos to your profile, your portfolio or a job request.</string>
<key>CFBundleLocalizations</key>
<array><string>ht</string><string>fr</string><string>en</string></array>
<key>LSApplicationQueriesSchemes</key>
<array><string>tel</string><string>mailto</string></array>
```

`ios/Runner/AppDelegate.swift`

```swift
GMSServices.provideAPIKey("YOUR_MAPS_IOS_KEY")
```

Xcode → Signing & Capabilities: **Push Notifications**, **Background Modes →
Remote notifications**, and **Sign in with Apple**. Minimum deployment target
iOS 13.

## Google Maps keys

Create two restricted keys in Google Cloud (Maps SDK for Android, Maps SDK for
iOS). Restrict the Android key by package name + SHA-1 and the iOS key by
bundle id, so a leaked key cannot be billed by anyone else.

## Locale note

Haitian Creole (`ht`) has no bundle in `flutter_localizations`; the app
registers fallback delegates that serve the French bundle for built-in widget
strings. Declaring `ht` in `CFBundleLocalizations` is what makes iOS report the
locale to the app at all.
