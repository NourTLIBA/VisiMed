-keep class android.webkit.* { *; }
-keepclassmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}
