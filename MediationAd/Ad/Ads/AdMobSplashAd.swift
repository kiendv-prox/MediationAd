//
//  SplashAd.swift
//
//
//  Created by Trịnh Xuân Minh on 06/09/2023.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

class AdMobSplashAd: NSObject, @preconcurrency ReuseAdProtocol, @unchecked Sendable {
    private var splashAd: InterstitialAd?
    private var adUnitID: String?
    private var placement: String?
    private var name: String?
    private var presentState = false
    private var isLoading = false
    private var timeout: Double?
    private var didResponse = false
    private var didLoadFail: Handler?
    private var didLoadSuccess: Handler?
    private var didFail: Handler?
    private var willPresent: Handler?
    private var didEarnReward: Handler?
    private var didHide: Handler?
    
    private var timeoutTimer: Timer?
    
    func config(didFail: Handler?, didSuccess: Handler?) {
        self.didLoadFail = didFail
        self.didLoadSuccess = didSuccess
    }
    
    func config(id: String, name: String) {
        self.adUnitID = id
        self.name = name
        load()
    }
    
    func config(timeout: Double) {
        self.timeout = timeout
    }
    
    func isPresent() -> Bool {
        return presentState
    }
    
    func isExist() -> Bool {
        return splashAd != nil
    }
    
    @MainActor
    func show(placement: String,
              rootViewController: UIViewController,
              didFail: Handler?,
              willPresent: Handler?,
              didEarnReward: Handler?,
              didHide: Handler?
    ) {
        guard !presentState else {
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Display failure - ads are being displayed! (\(placement))")
            didFail?()
            return
        }
        
        LogEventManager.shared.log(event: .adShowRequest(.admob, placement))
        
        guard isExist() else {
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Display failure - not ready to show! (\(placement))")
            LogEventManager.shared.log(event: .adShowNoReady(.admob, placement))
            didFail?()
            return
        }
        
        LogEventManager.shared.log(event: .adShowReady(.admob, placement))
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Requested to show! (\(placement))")
        
        self.placement = placement
        self.didFail = didFail
        self.willPresent = willPresent
        self.didHide = didHide
        self.didEarnReward = didEarnReward
        splashAd?.present(from: rootViewController)
    }
}

extension AdMobSplashAd: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error
    ) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Did fail to show content! (\(String(describing: name)))")
        if let placement {
            LogEventManager.shared.log(event: .adShowFail(.admob, placement, error))
        }
        didFail?()
        self.splashAd = nil
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Will display! (\(String(describing: name)))")
        if let placement {
            LogEventManager.shared.log(event: .adShowSuccess(.admob, placement))
        }
        willPresent?()
        self.presentState = true
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Did hide! (\(String(describing: name)))")
        if let placement {
            LogEventManager.shared.log(event: .adShowHide(.admob, placement))
        }
        didHide?()
        self.presentState = false
        self.splashAd = nil
    }
}

extension AdMobSplashAd {
    private func load() {
        guard !isLoading else {
            return
        }
        
        Task {
            guard let adUnitID else {
                AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Failed to load - not initialized yet! Please install ID.")
                Task {@MainActor in
                    didLoadFail?()
                }
                return
            }
            
            self.isLoading = true
            
            // start timeout
            registerTimeout()
            
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Start load! (\(String(describing: name)))")
            if let name {
                LogEventManager.shared.log(event: .adLoadRequest(.admob, name))
                TimeManager.shared.start(event: .adLoad(name))
            }
            
            do {
                let ad = try await loadInterAd(adUnitID)
                isLoading = false
                guard !didResponse else {
                    return
                }
                didResponse = true
                onLoadAdSuccess(ad)
            } catch {
                isLoading = false
                guard !didResponse else {
                    return
                }
                didResponse = true
                
                AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Load fail (\(String(describing: name))) - \(String(describing: error))!")
                if let name {
                    LogEventManager.shared.log(event: .adLoadFail(.admob, name, error))
                }
                Task {@MainActor in
                    didLoadFail?()
                }
            }
        }
    }
}

extension AdMobSplashAd {
    private func loadInterAd(_ id: String) async throws -> InterstitialAd {
        let request = Request()
        return try await InterstitialAd.load(with: id, request: request)
    }
    
    private func onListerningPaidEvent(_ ad: InterstitialAd) {
        ad.paidEventHandler = { adValue in
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Did pay revenue(\(adValue.value))!")
            if let placement = self.placement {
                LogEventManager.shared.log(event: .adPayRevenue(.admob, placement))
                if adValue.value == 0 {
                    LogEventManager.shared.log(event: .adNoRevenue(.admob, placement))
                }
            }
            
            let adRevenueParams: [AnyHashable: Any] = [
                kAppsFlyerAdRevenueCountry: Locale.current.regionCodeString ?? "US",
                kAppsFlyerAdRevenueAdUnit: ad.adUnitID,
                kAppsFlyerAdRevenueAdType: "AdMob_Interstitial_Splash"
            ]
            
            AppsFlyerAdRevenue.shared().logAdRevenue(
                monetizationNetwork: "admob",
                mediationNetwork: MediationNetworkType.googleAdMob,
                eventRevenue: adValue.value,
                revenueCurrency: adValue.currencyCode,
                additionalParameters: adRevenueParams)
        }
    }
    
    private func onLoadAdSuccess(_ ad: InterstitialAd) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Did load! (\(String(describing: name)))")
        if let name {
            let time = TimeManager.shared.end(event: .adLoad(name))
            LogEventManager.shared.log(event: .adLoadSuccess(.admob, name, time))
        }
        
        self.splashAd = ad
        self.splashAd?.fullScreenContentDelegate = self
        Task {@MainActor in
            didLoadSuccess?()
        }
        
        let network = ad.responseInfo.adNetworkInfoArray.first
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Adapter(\(String(describing: network)))!")
        
        onListerningPaidEvent(ad)
    }
}

extension AdMobSplashAd {
    private func registerTimeout() {
        guard let timeout, timeoutTimer == nil else {return}
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            guard !didResponse else {
                releaseTimeout()
                return
            }
            self.didResponse = true
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [SplashAd] Load fail (\(String(describing: name))) - timeout!")
            if let name {
                LogEventManager.shared.log(event: .adLoadTimeout(.admob, name))
            }
            didLoadFail?()
            releaseTimeout()
        })
    }
    
    private func releaseTimeout() {
        guard timeoutTimer != nil else {return}
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}
