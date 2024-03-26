//
//  SessionStorage.swift
//  Rudder
//
//  Created by Pallab Maiti on 16/07/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

public enum SessionStorageKeys: String {
    case deviceToken
    case advertisingId
    case appTrackingConsent
    case globalOption
    case context
}

public protocol SessionStorageProtocol {
    func write<T: Any>(_ key: SessionStorageKeys, value: T?)
    func read<T: Any>(_ key: SessionStorageKeys) -> T?
}

class SessionStorage: SessionStorageProtocol {
    @ReadWriteLock private var deviceToken: String?
    @ReadWriteLock private var advertisingId: String?
    @ReadWriteLock private var appTrackingConsent: AppTrackingConsent?
    @ReadWriteLock private var globalOption: GlobalOptionType?
    @ReadWriteLock private var context: Context?
    
    func write<T: Any>(_ key: SessionStorageKeys, value: T?) {
        switch key {
        case .deviceToken:
            deviceToken = value as? String
        case .advertisingId:
            advertisingId = value as? String
        case .appTrackingConsent:
            appTrackingConsent = value as? AppTrackingConsent
        case .globalOption:
            globalOption = value as? GlobalOptionType
        case .context:
            if let value = value as? MessageContext {
                do {
                    let data = try JSONSerialization.data(withJSONObject: value)
                    context = try JSONDecoder().decode(Context.self, from: data)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func read<T: Any>(_ key: SessionStorageKeys) -> T? {
        var result: T?
        switch key {
        case .deviceToken:
            result = deviceToken as? T
        case .advertisingId:
            result = advertisingId as? T
        case .appTrackingConsent:
            result = appTrackingConsent as? T
        case .globalOption:
            result = globalOption as? T
        case .context:
            result = context as? T
        }
        return result
    }
}
