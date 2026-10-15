import Flutter
import UIKit
import Security
import CryptoKit

/// Handles the `com.example.chat_app/key_manager` Flutter MethodChannel.
///
/// Supported methods:
/// - `generateKeyPair`  { alias: String, requireAuth: Bool } → String (PEM public key)
/// - `signData`         { alias: String, data: FlutterStandardTypedData } → FlutterStandardTypedData
/// - `hasKeyPair`       { alias: String } → Bool (Hardware check)
/// - `deleteKeyPair`    { alias: String } → nil
///
/// Private keys are stored in the **Secure Enclave** (kSecAttrTokenIDSecureEnclave)
/// on physical devices, with a safe fallback to the system Keychain on Simulators.
@objc class KeyManagerPlugin: NSObject, FlutterPlugin {

    private static let channelName = "com.example.chat_app/key_manager"
    private static let defaultAlias = "mtls_client_key"

    // MARK: - Registration

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = KeyManagerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - Method Call Handler

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        let alias = args["alias"] as? String ?? Self.defaultAlias

        switch call.method {
        case "generateKeyPair":
            let requireAuth = args["requireAuth"] as? Bool ?? false
            generateKeyPair(alias: alias, requireAuth: requireAuth, result: result)

        case "signData":
            guard let dataWrapper = args["data"] as? FlutterStandardTypedData else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing 'data' argument", details: nil))
                return
            }
            signData(alias: alias, data: dataWrapper.data, result: result)

        case "hasKeyPair":
            hasKeyPair(alias: alias, result: result)

        case "deleteKeyPair":
            deleteKeyPair(alias: alias, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Key Generation (Secure Enclave with Keychain Fallback)

    private func generateKeyPair(alias: String, requireAuth: Bool, result: @escaping FlutterResult) {
        // Delete any existing key first.
        deleteKeyFromKeychain(alias: alias)

        // Attempt Secure Enclave generation first; fallback to standard Keychain (e.g., on Simulator).
        var privateKey: SecKey?
        var lastError: Unmanaged<CFError>?

        #if !targetEnvironment(simulator)
        if let seAttributes = buildKeyAttributes(alias: alias, useSecureEnclave: true, requireAuth: requireAuth) {
            privateKey = SecKeyCreateRandomKey(seAttributes as CFDictionary, &lastError)
        }
        #endif

        // Fallback if running on Simulator or if Secure Enclave creation failed.
        if privateKey == nil {
            lastError = nil
            if let kcAttributes = buildKeyAttributes(alias: alias, useSecureEnclave: false, requireAuth: false) {
                privateKey = SecKeyCreateRandomKey(kcAttributes as CFDictionary, &lastError)
            }
        }

        guard let validPrivateKey = privateKey else {
            let msg = lastError?.takeRetainedValue().localizedDescription ?? "Unknown key generation error"
            result(FlutterError(code: "KEY_GEN_ERROR", message: msg, details: nil))
            return
        }

        // Extract the public key and export it as PEM.
        guard let publicKey = SecKeyCopyPublicKey(validPrivateKey) else {
            result(FlutterError(code: "KEY_GEN_ERROR", message: "Failed to extract public key", details: nil))
            return
        }

        guard let pubKeyPem = exportPublicKeyAsPEM(publicKey) else {
            result(FlutterError(code: "KEY_GEN_ERROR", message: "Failed to export public key as PEM", details: nil))
            return
        }

        result(pubKeyPem)
    }

    private func buildKeyAttributes(alias: String, useSecureEnclave: Bool, requireAuth: Bool) -> [String: Any]? {
        guard let tagData = alias.data(using: .utf8) else { return nil }

        var privateKeyAttrs: [String: Any] = [
            kSecAttrIsPermanent as String: true,
            kSecAttrApplicationTag as String: tagData,
        ]

        if useSecureEnclave {
            var flags: SecAccessControlCreateFlags = [.privateKeyUsage]
            if requireAuth {
                // Invalidates key if FaceID/TouchID enrollment changes (matches Android behavior).
                flags.insert(.biometryCurrentSet)
            }

            guard let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                flags,
                nil
            ) else {
                return nil
            }
            privateKeyAttrs[kSecAttrAccessControl as String] = access
        } else {
            privateKeyAttrs[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        var attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: privateKeyAttrs,
        ]

        if useSecureEnclave {
            attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        }

        return attributes
    }

    // MARK: - Key Verification

    private func hasKeyPair(alias: String, result: @escaping FlutterResult) {
        let exists = loadPrivateKey(alias: alias) != nil
        result(exists)
    }

    // MARK: - Signing

    private func signData(alias: String, data: Data, result: @escaping FlutterResult) {
        guard let privateKey = loadPrivateKey(alias: alias) else {
            result(FlutterError(code: "KEY_NOT_FOUND", message: "No private key for alias: \(alias)", details: nil))
            return
        }

        let algorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256

        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            result(FlutterError(code: "SIGN_ERROR", message: "Algorithm not supported", details: nil))
            return
        }

        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            algorithm,
            data as CFData,
            &error
        ) else {
            let cfError = error?.takeRetainedValue()
            let msg = cfError?.localizedDescription ?? "Unknown signing error"
            result(FlutterError(code: "SIGN_ERROR", message: msg, details: nil))
            return
        }

        result(FlutterStandardTypedData(bytes: signature as Data))
    }

    // MARK: - Key Deletion

    private func deleteKeyPair(alias: String, result: @escaping FlutterResult) {
        deleteKeyFromKeychain(alias: alias)
        result(nil)
    }

    // MARK: - Private Helpers

    /// Loads the private key stored in the Secure Enclave / Keychain for [alias].
    private func loadPrivateKey(alias: String) -> SecKey? {
        guard let tagData = alias.data(using: .utf8) else { return nil }
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tagData,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let unwrappedItem = item else { return nil }
        return (unwrappedItem as! SecKey)
    }

    /// Removes all Keychain entries matching [alias].
    private func deleteKeyFromKeychain(alias: String) {
        guard let tagData = alias.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tagData,
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Converts an EC public key to a PEM-encoded string.
    ///
    /// iOS exports EC public keys in X9.63 uncompressed format (65 bytes).
    /// We prepend the SubjectPublicKeyInfo (SPKI) DER header for P-256 so the
    /// resulting PEM is compatible with standard tools and mTLS handshakes.
    private func exportPublicKeyAsPEM(_ key: SecKey) -> String? {
        var error: Unmanaged<CFError>?
        guard let keyData = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            return nil
        }

        // SPKI header for EC P-256 (secp256r1)
        // OID: 1.2.840.10045.2.1 (id-ecPublicKey) + 1.2.840.10045.3.1.7 (prime256v1)
        let spkiHeader: [UInt8] = [
            0x30, 0x59,
            0x30, 0x13,
            0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01,
            0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07,
            0x03, 0x42, 0x00,
        ]

        var derData = Data(spkiHeader)
        derData.append(keyData)

        let b64 = derData.base64EncodedString(options: .lineLength64Characters)
        return "-----BEGIN PUBLIC KEY-----\n\(b64)\n-----END PUBLIC KEY-----"
    }
}