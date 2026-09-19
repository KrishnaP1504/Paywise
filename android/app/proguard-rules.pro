# ==========================================
# 📱 PAYWISE - PRODUCTION PROGUARD / R8 RULES
# ==========================================

# 1. Flutter Engine & Embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# 2. Local Authentication (Biometrics)
-keep class io.flutter.plugins.localauth.** { *; }
-dontwarn androidx.biometric.**

# 3. Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# 4. Firebase Core & Authentication & Firestore
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# 5. Local Notifications & Desugaring
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# 6. Keep native Kotlin serialization & Parcelable models if applicable
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}
