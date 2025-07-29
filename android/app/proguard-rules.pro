# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Supabase
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }
-keep class org.postgresql.** { *; }
-dontwarn io.supabase.**
-dontwarn com.google.gson.**
-dontwarn org.postgresql.**

# Awesome Notifications
-keep class me.carda.awesome_notifications.** { *; }
-dontwarn me.carda.awesome_notifications.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Background Fetch
-keep class com.transistorsoft.flutter.backgroundfetch.** { *; }
-dontwarn com.transistorsoft.flutter.backgroundfetch.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
} 