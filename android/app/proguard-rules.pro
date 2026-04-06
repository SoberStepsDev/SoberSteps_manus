-dontwarn com.fasterxml.jackson.core.**
-dontwarn com.google.auto.value.**

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Supabase / Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keep,includedescriptorclasses class com.sobersteps.sobersteps.**$$serializer { *; }
-keepclassmembers class com.sobersteps.sobersteps.** {
    *** Companion;
}
-keepclasseswithmembers class com.sobersteps.sobersteps.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# OkHttp (used by Supabase)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# OneSignal + FCM (release minify)
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# Google Play Billing
-keep class com.android.billingclient.** { *; }

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-dontwarn kotlinx.coroutines.**

# Gson / JSON
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Prevent stripping R8 from removing critical classes
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
