# flutter_secure_storage's EncryptedSharedPreferences implementation pulls in
# Tink/BouncyCastle/Conscrypt as optional dependencies for algorithms this app
# never uses; R8 warns about the missing classes unless told to ignore them.
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-keep class androidx.security.crypto.** { *; }
