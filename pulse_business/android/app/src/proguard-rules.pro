# Flutter and Dart
-keep class io.flutter.** { *; }
-keep class dart.** { *; }

# Firebase - Keep all Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep all your model classes from being obfuscated
-keep class **.models.** { *; }

# Keep methods that Firebase uses for serialization
-keepclassmembers class * {
    public <init>();
    public <init>(...);
    public static ** fromMap(...);
    public java.util.Map toMap();
    public ** copyWith(...);
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Don't optimize Firebase calls
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.auth.** { *; }