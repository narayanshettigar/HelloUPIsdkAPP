//
//  AES_Algo.swift
//  SampleAudioApp
//
//  Created by Narayan Shettigar on 17/07/24.
//

import Foundation
import Contacts
import CommonCrypto

final class AESCrypt {
    private static let TAG = "AESCrypt"
    private static let AES_MODE = kCCAlgorithmAES
    private static let CHARSET = String.Encoding.utf8
    private static let HASH_ALGORITHM = CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256)
    private static let ivBytes: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                           0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    private static let DEBUG_LOG_ENABLED = false

    private static func generateKey(password: String) throws -> Data {
        let passwordData = password.data(using: .utf8)!
        var key = Data(count: kCCKeySizeAES256)
        let salt = Data() // Empty salt, matching the original code
        let rounds = 10000 // Number of PBKDF2 rounds

        let status = key.withUnsafeMutableBytes { keyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordBytes.baseAddress, passwordBytes.count,
                    salt.withUnsafeBytes { $0.baseAddress }, salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    UInt32(rounds),
                    keyBytes.baseAddress, keyBytes.count)
            }
        }
        
        guard status == kCCSuccess else {
            throw AESError.keyGenerationError
        }
        return key
    }

    static func encrypt(password: String, message: String) throws -> String {
        let key = try generateKey(password: password)
        log("key", key)
        log("message", message)
        print("key : \(key)")
        print("message : \(message)")
        let cipherText = try encrypt(key: key, iv: Data(ivBytes), message: message.data(using: CHARSET)!)
        print("this is cipherText:- \(cipherText)")
        let encoded = cipherText.base64EncodedString(options: [])
        print("this is encoded cipherText:- \(encoded)")
        log("Base64.NO_WRAP", encoded)
        var res = try decrypt(password: password, base64EncodedCipherText: encoded)
        print("decryt : \(res)")
        return encoded
    }

    private static func encrypt(key: Data, iv: Data, message: Data) throws -> Data {
        let bufferSize = message.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        
        var numBytesEncrypted: Int = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                message.withUnsafeBytes { messageBytes in
                    buffer.withUnsafeMutableBytes { bufferBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(AES_MODE),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, keyBytes.count,
                            ivBytes.baseAddress,
                            messageBytes.baseAddress, messageBytes.count,
                            bufferBytes.baseAddress, bufferSize,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw AESError.encryptionError
        }
        
        buffer.count = numBytesEncrypted
        log("cipherText", buffer)
        return buffer
    }

    static func decrypt(password: String, base64EncodedCipherText: String) throws -> String {
        let key = try generateKey(password: password)
        log("base64EncodedCipherText", base64EncodedCipherText)
        
        guard let decodedCipherText = Data(base64Encoded: base64EncodedCipherText, options: []) else {
            throw AESError.decodingError
        }
        log("decodedCipherText", decodedCipherText)
        
        let decryptedBytes = try decrypt(key: key, iv: Data(ivBytes), decodedCipherText: decodedCipherText)
        log("decryptedBytes", decryptedBytes)
        
        guard let message = String(data: decryptedBytes, encoding: CHARSET) else {
            throw AESError.decodingError
        }
        print("decrypt message:- \(message)")
        return message
    }

    private static func decrypt(key: Data, iv: Data, decodedCipherText: Data) throws -> Data {
        let bufferSize = decodedCipherText.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        
        var numBytesDecrypted: Int = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                decodedCipherText.withUnsafeBytes { cipherTextBytes in
                    buffer.withUnsafeMutableBytes { bufferBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(AES_MODE),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, keyBytes.count,
                            ivBytes.baseAddress,
                            cipherTextBytes.baseAddress, cipherTextBytes.count,
                            bufferBytes.baseAddress, bufferSize,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw AESError.decryptionError
        }
        
        buffer.count = numBytesDecrypted
        log("decryptedBytes", buffer)
        return buffer
    }

    private static func log(_ what: String, _ bytes: Data) {
        if DEBUG_LOG_ENABLED {
            print("\(TAG): \(what)[\(bytes.count)] [\(bytesToHex(bytes))]")
        }
    }

    private static func log(_ what: String, _ value: String) {
        if DEBUG_LOG_ENABLED {
            print("\(TAG): \(what)[\(value.count)] [\(value)]")
        }
    }

    private static func bytesToHex(_ bytes: Data) -> String {
        return bytes.map { String(format: "%02X", $0) }.joined()
    }

    private init() {}
}

enum AESError: Error {
    case keyGenerationError
    case encryptionError
    case decryptionError
    case decodingError
}

extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}
