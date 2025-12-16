-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
# Keep Stripe classes
-keep class com.stripe.** { *; }

# Proguard rules for SABO Arena release build
# Keep Flutter and Dart classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Supabase classes
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Keep Geolocator classes
-keep class com.baseflow.geolocator.** { *; }

# Keep Google services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom classes that might be used via reflection
-keep class com.sabo_arena.app.** { *; }

# Play Core library - allow missing classes for standard APK builds
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Fix for deprecated RenderScript warnings
-dontwarn android.renderscript.**

# Mobile Scanner deprecation warnings - updated for v7.1.2
-dontwarn dev.steenbakker.mobile_scanner.**
-keep class dev.steenbakker.mobile_scanner.** { *; }

# Flutter Toast deprecation warnings - updated for v9.0.0
-dontwarn io.github.ponnamkarthik.toast.**
-keep class io.github.ponnamkarthik.toast.** { *; }

# Geolocator v14 warnings
-dontwarn com.baseflow.geolocator.**

# Permission Handler v12 warnings  
-dontwarn com.baseflow.permissionhandler.**

# Connectivity Plus v7 warnings
-dontwarn dev.fluttercommunity.plus.connectivity.**

# File Picker v10 warnings
-dontwarn com.mr.flutter.plugin.filepicker.**

# Suppress unused ProGuard rule warnings for j$.util classes
-dontwarn j$.util.**

# Optimization settings theo khuyến nghị Google
-printmapping mapping.txt
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes *Annotation*

# Tối ưu hóa R8 - minimal obfuscation for better debugging
-dontobfuscate
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*
-optimizationpasses 2