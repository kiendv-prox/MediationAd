//
//  RemoteHandler.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 02/08/2024.
//

import Foundation
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

public typealias RemoteHandler = ((RemoteManager.State, RemoteConfig) -> Void)
