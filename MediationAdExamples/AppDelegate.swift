//
//  AppDelegate.swift
//  MediationAdExamples
//
//  Created by Trịnh Xuân Minh on 02/08/2024.
//

import UIKit
import MediationAd
import FirebaseAnalytics
import FirebaseCore
import Combine

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
    private lazy var remoteManager = RemoteManager.shared
    private lazy var subscriptions = Set<AnyCancellable>()
  
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let appID = "6473620562"
    let devKey = "PdFSXQuoCZKy2mQvtsMXsW"
    let issuerID = "90feb1ef-b49e-466f-bdf0-6c854e6042e2"
    let keyID = "6U7525RU8W"
    let privateKey = """
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgPIQil7g03C5nf0Cr
    UO78c9YuqPRO11jV7/UN3frXe6ugCgYIKoZIzj0DAQehRANCAAQYWA+t6rSkTz+9
    WxVKpmxLLqEc2O9sPCA7Lhq0/nI1mHSHPi9Lge5ZBEzqisiEgVvZ5OuX7JlfUC4r
    Gu7+MCYD
    -----END PRIVATE KEY-----
    """
    let maxSdkKey = "hyf3VVXFdwMCaKeA84k0ll1TfmnfTxZ9tEDNlmdNg-ZFJCQSH9T1uUUXEFCiBnt3_4Qlr26V1gmKtAn9KEACkf"
    let adConfigKey = "AdConfig_Test_0_0_22"
    
    let idfa = "35513F2E-AA97-4D67-AA04-CC99C59B50A8"
    let umpTestDeviceID = "132919C6-7708-44DA-8365-5FB2824F4D60"
    let gadTestDeviceID = "b27306cfc9cfaa08588524ca26534e42"
    
    AppManager.shared.setTest([idfa, umpTestDeviceID, gadTestDeviceID], testModeMax: true)
//    AppManager.shared.activeDebug(.event)
//    AppManager.shared.activeDebug(.consent(true))
    
      FirebaseApp.configure()
      
    if let url = Bundle.main.url(forResource: "AdDefaultValue", withExtension: "json"),
       let defaultData = try? Data(contentsOf: url) {
        let config = AppConfig(appID: appID, issuerID: issuerID, keyID: keyID, privateKey: privateKey, adConfigKey: adConfigKey, defaultData: defaultData, maxSdkKey: maxSdkKey, devKey: devKey, trackingTimeout: 20)
        
        AppManager.shared.initialize(app: config)
    }
      
      TrackingManager.shared
          .statusSubject
          .sink { status in
              Analytics.setAnalyticsCollectionEnabled(status)
          }.store(in: &subscriptions)
      
      remoteManager.$remoteState
          .filter({ $0 == .success })
          .map({ _ in self.remoteManager.remoteConfig.configValue(forKey: adConfigKey).dataValue })
          .sink { [weak self] data in
              guard self != nil else { return }
              AppManager.shared.remoteConfigSubject.send(data)
          }.store(in: &subscriptions)
      
      NetworkManager.shared
          .$isNetwordConnected
          .filter({ $0 })
          .sink { [weak self] _ in
              self?.remoteManager.initialize()
          }.store(in: &subscriptions)
    return true
  }
}
