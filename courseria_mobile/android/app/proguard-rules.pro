# Flutter optimization
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# GetX
-keep class com.getx.** { *; }
-keep class io.flutter.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.supabase.** { *; }
-keep class com.example.courseria_mobile.** { *; }
-keep class * extends androidx.multidex.MultiDexApplication { *; }
-keepattributes Signature, InnerClasses, EnclosingMethod
-dontwarn io.flutter.**

# Attributes & Warnings
-dontwarn com.getx.**
-dontwarn okhttp3.**
-dontwarn retrofit2.**

# Flutter Secure Storage
-keep class crypto.** { *; }
-keep class com.it_nomads.flutter_secure_storage.** { *; }

# Google Mobile Services Auth specific rules
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-keep class com.google.android.gms.auth.api.credentials.Credential { *; }
-keep class com.google.android.gms.auth.api.credentials.Credential$Builder { *; }
-keep class com.google.android.gms.auth.api.credentials.CredentialPickerConfig { *; }
-keep class com.google.android.gms.auth.api.credentials.CredentialPickerConfig$Builder { *; }
-keep class com.google.android.gms.auth.api.credentials.CredentialRequest { *; }
-keep class com.google.android.gms.auth.api.credentials.CredentialRequest$Builder { *; }
-keep class com.google.android.gms.auth.api.credentials.CredentialRequestResponse { *; }
-keep class com.google.android.gms.auth.api.credentials.Credentials { *; }
-keep class com.google.android.gms.auth.api.credentials.CredentialsClient { *; }
-keep class com.google.android.gms.auth.api.credentials.HintRequest { *; }
-keep class com.google.android.gms.auth.api.credentials.HintRequest$Builder { *; }

-keep class fman.ge.smart_auth.** { *; }

# R8 generated missing rules
-dontwarn com.google.android.gms.auth.api.credentials.Credential$Builder
-dontwarn com.google.android.gms.auth.api.credentials.Credential
-dontwarn com.google.android.gms.auth.api.credentials.CredentialPickerConfig$Builder
-dontwarn com.google.android.gms.auth.api.credentials.CredentialPickerConfig
-dontwarn com.google.android.gms.auth.api.credentials.CredentialRequest$Builder
-dontwarn com.google.android.gms.auth.api.credentials.CredentialRequest
-dontwarn com.google.android.gms.auth.api.credentials.CredentialRequestResponse
-dontwarn com.google.android.gms.auth.api.credentials.Credentials
-dontwarn com.google.android.gms.auth.api.credentials.CredentialsClient
-dontwarn com.google.android.gms.auth.api.credentials.HintRequest$Builder
-dontwarn com.google.android.gms.auth.api.credentials.HintRequest
