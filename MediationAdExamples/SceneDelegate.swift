//
//  SceneDelegate.swift
//  MediationAdExamples
//
//  Created by Trịnh Xuân Minh on 02/08/2024.
//

import UIKit
import MediationAd

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func sceneDidBecomeActive(_ scene: UIScene) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
//            TrackingManager.shared.requestAuthorization(completed: nil)
//        })
//        Task {
//            try await Task.sleep(nanoseconds: 5 * 1_000_000)
//            let _ = await TrackingManager.shared.requestAuthorization()
//        }
        
        guard let topVC = UIApplication.topViewController(), AppManager.shared.adConfigStatus else {
            return
        }
        AdManager.shared.show(type: .appOpen,
                              placement: AppText.AdName.appOpen,
                              rootViewController: topVC,
                              didFail: nil,
                              didHide: nil)
    }
}

