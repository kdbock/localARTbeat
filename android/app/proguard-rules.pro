# Stripe SDK rules
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# Keep Stripe SDK classes
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.view.** { *; }
-keep class com.stripe.android.paymentsheet.** { *; }

# CRITICAL: Keep Stripe 3D Secure / SCA Challenge classes to prevent crashes
# These classes are dynamically loaded and MUST be preserved
-keep class com.stripe.android.challenge.** { *; }
-keep class com.stripe.android.challenge.passive.** { *; }
-keep class com.stripe.android.challenge.passive.warmer.** { *; }
-keep class com.stripe.android.challenge.confirmation.** { *; }
-keep class com.stripe.android.attestation.** { *; }

# Keep ViewModels with their Factory inner classes
-keepclassmembers class com.stripe.android.challenge.passive.PassiveChallengeViewModel {
    public static ** Factory;
}
-keepclassmembers class com.stripe.android.attestation.AttestationViewModel {
    public static ** Factory;
}

# Preserve ViewModel constructors and factory methods
-keepclassmembers class * extends androidx.lifecycle.ViewModel {
    <init>(...);
}
-keep class * extends androidx.lifecycle.ViewModelProvider$Factory {
    <init>(...);
}

# Keep IntentConfirmationChallenge related classes
-keep class com.stripe.android.challenge.confirmation.IntentConfirmationChallenge** { *; }

# General rules for React Native
-keep class com.facebook.react.** { *; }
-keep class com.facebook.hermes.** { *; }

# Keep your application classes
-keep class com.wordnerd.artbeat.** { *; }

# Suppress warnings for unused ProGuard rules from dependencies
-dontwarn j$.util.**
-dontwarn j$.util.concurrent.**
