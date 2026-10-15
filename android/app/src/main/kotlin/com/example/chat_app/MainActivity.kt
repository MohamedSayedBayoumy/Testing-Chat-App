package com.example.chat_app

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.security.keystore.UserNotAuthenticatedException
import android.util.Base64
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import java.security.spec.ECGenParameterSpec

/**
 * MainActivity acts as the host for the [KeyManagerPlugin] method channel.
 *
 * Extends [FlutterFragmentActivity] (instead of [FlutterActivity]) so that
 * the biometric prompt launched by local_auth can attach to a FragmentManager.
 */
class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        KeyManagerPlugin.register(flutterEngine, this)
    }
}

/**
 * Handles the `com.example.chat_app/key_manager` [MethodChannel].
 *
 * Supported methods:
 * - `generateKeyPair`  { alias: String, requireAuth: Boolean } → String (PEM public key)
 * - `signData`         { alias: String, data: ByteArray } → ByteArray (DER signature)
 * - `hasKeyPair`       { alias: String } → Boolean (Hardware & validity check)
 * - `deleteKeyPair`    { alias: String } → null
 *
 * Keys live exclusively in the **Android Keystore** provider.
 * When the device hardware supports it (`StrongBox`), the private key is
 * generated and stored inside the dedicated security chip (equivalent to the
 * Secure Enclave on iOS). If unavailable, it safely falls back to the TEE.
 */
object KeyManagerPlugin : MethodChannel.MethodCallHandler {

    private const val CHANNEL = "com.example.chat_app/key_manager"
    private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
    private const val DEFAULT_ALIAS = "mtls_client_key"
    private const val AUTH_VALIDITY_DURATION_SECONDS = 30

    fun register(flutterEngine: FlutterEngine, activity: FlutterFragmentActivity) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "generateKeyPair" -> {
                val alias = call.argument<String>("alias") ?: DEFAULT_ALIAS
                val requireAuth = call.argument<Boolean>("requireAuth") ?: false
                generateKeyPair(alias, requireAuth, result)
            }

            "signData" -> {
                val alias = call.argument<String>("alias") ?: DEFAULT_ALIAS
                val data = call.argument<ByteArray>("data")
                if (data == null) {
                    result.error("INVALID_ARGS", "Missing 'data' argument", null)
                } else {
                    signData(alias, data, result)
                }
            }

            "hasKeyPair" -> {
                val alias = call.argument<String>("alias") ?: DEFAULT_ALIAS
                hasKeyPair(alias, result)
            }

            "deleteKeyPair" -> {
                val alias = call.argument<String>("alias") ?: DEFAULT_ALIAS
                deleteKeyPair(alias, result)
            }

            else -> result.notImplemented()
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Key generation (with StrongBox -> TEE Fallback)
    // ──────────────────────────────────────────────────────────────────────

    private fun generateKeyPair(
        alias: String,
        requireAuth: Boolean,
        result: MethodChannel.Result,
    ) {
        try {
            deleteKeyFromStore(alias)

            val keyPairGenerator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_EC,
                KEYSTORE_PROVIDER,
            )

            val keyPair: KeyPair = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                try {
                    val strongBoxSpec = buildKeyGenSpec(alias, useStrongBox = true, requireAuth = requireAuth)
                    keyPairGenerator.initialize(strongBoxSpec)
                    keyPairGenerator.generateKeyPair()
                } catch (e: Exception) {
                    android.util.Log.e("KeyManager", "StrongBox failed, trying TEE: ${e.message}", e)
                    val teeSpec = buildKeyGenSpec(alias, useStrongBox = false, requireAuth = requireAuth)
                    keyPairGenerator.initialize(teeSpec)
                    keyPairGenerator.generateKeyPair()
                }
            } else {
                val teeSpec = buildKeyGenSpec(alias, useStrongBox = false, requireAuth = requireAuth)
                keyPairGenerator.initialize(teeSpec)
                keyPairGenerator.generateKeyPair()
            }

            val publicKeyBytes = keyPair.public.encoded
            val b64 = Base64.encodeToString(publicKeyBytes, Base64.NO_WRAP)
            val pem = buildString {
                appendLine("-----BEGIN PUBLIC KEY-----")
                b64.chunked(64).forEach { appendLine(it) }
                append("-----END PUBLIC KEY-----")
            }

            result.success(pem)
        } catch (e: Exception) {
            android.util.Log.e("KeyManager", "Fatal Key Gen Error: ${e.message}", e)
            result.error("KEY_GEN_ERROR", "Failed to generate key pair: ${e.javaClass.simpleName} - ${e.message}", e)
        }
    }

    private fun buildKeyGenSpec(
        alias: String,
        useStrongBox: Boolean,
        requireAuth: Boolean,
    ): KeyGenParameterSpec {
        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setKeySize(256)
            .setUserAuthenticationRequired(requireAuth)

        if (requireAuth) {
            // Allow key usage for 30 seconds after local_auth biometric success.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                builder.setUserAuthenticationParameters(
                    AUTH_VALIDITY_DURATION_SECONDS,
                    KeyProperties.AUTH_BIOMETRIC_STRONG or KeyProperties.AUTH_DEVICE_CREDENTIAL,
                )
            } else {
                @Suppress("DEPRECATION")
                builder.setUserAuthenticationValidityDurationSeconds(AUTH_VALIDITY_DURATION_SECONDS)
            }

            // Invalidate the key if a new fingerprint/face is enrolled on the device.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                builder.setInvalidatedByBiometricEnrollment(true)
            }
        }

        if (useStrongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        }

        return builder.build()
    }

    // ──────────────────────────────────────────────────────────────────────
    // Key verification & hardware validity check
    // ──────────────────────────────────────────────────────────────────────

    private fun hasKeyPair(alias: String, result: MethodChannel.Result) {
        try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
            if (!keyStore.containsAlias(alias)) {
                return result.success(false)
            }

            val privateKey = keyStore.getKey(alias, null) as? PrivateKey
                ?: return result.success(false)

            // Probe the key to ensure it hasn't been permanently invalidated by OS biometric changes.
            Signature.getInstance("SHA256withECDSA").initSign(privateKey)
            result.success(true)
        } catch (_: KeyPermanentlyInvalidatedException) {
            // Biometrics changed on the device; clean up the dead key and return false.
            deleteKeyFromStore(alias)
            result.success(false)
        } catch (_: UserNotAuthenticatedException) {
            // Key exists and is healthy, just waiting for biometric unlock.
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Signing
    // ──────────────────────────────────────────────────────────────────────

    private fun signData(alias: String, data: ByteArray, result: MethodChannel.Result) {
        try {
            val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
            val privateKey = keyStore.getKey(alias, null) as? PrivateKey
                ?: return result.error("KEY_NOT_FOUND", "No key found for alias: $alias", null)

            val signature = Signature.getInstance("SHA256withECDSA").apply {
                initSign(privateKey)
                update(data)
            }.sign()

            result.success(signature)
        } catch (e: KeyPermanentlyInvalidatedException) {
            deleteKeyFromStore(alias)
            result.error(
                "KEY_INVALIDATED",
                "Biometric enrollment changed. Key has been invalidated and deleted.",
                null,
            )
        } catch (e: UserNotAuthenticatedException) {
            result.error(
                "AUTH_REQUIRED",
                "Biometric authentication is required before signing.",
                null,
            )
        } catch (e: Exception) {
            result.error("SIGN_ERROR", e.message, null)
        }
    }

    // ──────────────────────────────────────────────────────────────────────
    // Key deletion
    // ──────────────────────────────────────────────────────────────────────

    private fun deleteKeyPair(alias: String, result: MethodChannel.Result) {
        try {
            deleteKeyFromStore(alias)
            result.success(null)
        } catch (e: Exception) {
            result.error("DELETE_ERROR", e.message, null)
        }
    }

    private fun deleteKeyFromStore(alias: String) {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        if (keyStore.containsAlias(alias)) {
            keyStore.deleteEntry(alias)
        }
    }
}