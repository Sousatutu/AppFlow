# Protege os plugins do Flutter
-keep class io.flutter.plugins.** { *; }

# Protege a biblioteca padrao do Kotlin (resolve o erro kotlin/Result)
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Protege o DataStore
-keep class androidx.datastore.** { *; }