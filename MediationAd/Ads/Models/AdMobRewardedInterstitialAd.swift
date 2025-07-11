//
//  RewardedInterstitialAd.swift
//
//
//  Created by Trịnh Xuân Minh on 05/12/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

class AdMobRewardedInterstitialAd: NSObject, ReuseAdProtocol {
    private var rewardedInterstitialAd: RewardedInterstitialAd?
    private var adUnitID: String?
    private var placement: String?
    private var name: String?
    private var presentState = false
    private var isLoading = false
    private var retryAttempt = 0
    private var didLoadFail: Handler?
    private var didLoadSuccess: Handler?
    private var didShowFail: Handler?
    private var willPresent: Handler?
    private var didEarnReward: Handler?
    private var didHide: Handler?
    
    func config(didFail: Handler?, didSuccess: Handler?) {
        self.didLoadFail = didFail
        self.didLoadSuccess = didSuccess
    }
    
    func config(id: String, name: String) {
        self.adUnitID = id
        self.name = name
        load()
    }
    
    func isPresent() -> Bool {
        return presentState
    }
    
    func isExist() -> Bool {
        return rewardedInterstitialAd != nil
    }
    
    func show(placement: String,
              rootViewController: UIViewController,
              didFail: Handler?,
              willPresent: Handler?,
              didEarnReward: Handler?,
              didHide: Handler?
    ) {
        guard !presentState else {
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Display failure - ads are being displayed! (\(placement))")
            didFail?()
            return
        }
        
        LogEventManager.shared.log(event: .adShowRequest(.admob, placement))
        guard isReady() else {
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Display failure - not ready to show! (\(placement))")
            LogEventManager.shared.log(event: .adShowNoReady(.admob, placement))
            didFail?()
            return
        }
        
        LogEventManager.shared.log(event: .adShowReady(.admob, placement))
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Requested to show! (\(placement))")
        self.placement = placement
        self.didShowFail = didFail
        self.willPresent = willPresent
        self.didHide = didHide
        self.didEarnReward = didEarnReward
        
        rewardedInterstitialAd?
            .present(from: rootViewController,
                     userDidEarnRewardHandler: { [weak self] in
                guard let self else { return }
                LogEventManager.shared.log(event: .adEarnReward(.admob, placement))
                Task { @MainActor in
                    self.didEarnReward?()
                }
            })
    }
}

extension AdMobRewardedInterstitialAd: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error
    ) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Did fail to show content! (\(String(describing: name)))")
        if let placement {
            LogEventManager.shared.log(event: .adShowFail(.admob, placement, error))
        }
        didShowFail?()
        self.rewardedInterstitialAd = nil
        load()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Will display! (\(String(describing: name)))")
        if let placement {
            LogEventManager.shared.log(event: .adShowSuccess(.admob, placement))
        }
        willPresent?()
        self.presentState = true
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Did hide! (\(String(describing: name)))")
        if let placement {
            LogEventManager.shared.log(event: .adShowHide(.admob, placement))
        }
        didHide?()
        self.rewardedInterstitialAd = nil
        self.presentState = false
        load()
    }
}

extension AdMobRewardedInterstitialAd {
    private func isReady() -> Bool {
        if !isExist(), retryAttempt >= 1 {
            load()
        }
        return isExist()
    }
    
    private func load() {
        guard !isLoading else {
            return
        }
        
        guard !isExist() else {
            return
        }
        
        Task {
            guard let adUnitID else {
                AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Failed to load - not initialized yet! Please install ID.")
                return
            }
            
            isLoading = true
            
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Start load! (\(String(describing: name)))")
            if let name {
                LogEventManager.shared.log(event: .adLoadRequest(.admob, name))
                TimeManager.shared.start(event: .adLoad(name))
            }
            
            do {
                let ad = try await loadRewardAd(adUnitID)
                isLoading = false
                onLoadAdSuccess(ad)
            } catch {
                isLoading = false
                AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Load fail (\(String(describing: name))) - \(String(describing: error))!")
                self.retryAttempt += 1
                if let name {
                    LogEventManager.shared.log(event: .adLoadFail(.admob, name, error))
                }
                Task { @MainActor in
                    self.didLoadFail?()
                }
            }
        }
    }
}

extension AdMobRewardedInterstitialAd {
    private func loadRewardAd(_ id: String) async throws -> RewardedInterstitialAd  {
        let request = Request()
        return try await RewardedInterstitialAd.load(with: id, request: request)
    }
    
    private func onListeringPaidEvent(_ ad: RewardedInterstitialAd) {
        ad.paidEventHandler = { adValue in
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Did pay revenue(\(adValue.value))!")
            if let placement = self.placement {
                LogEventManager.shared.log(event: .adPayRevenue(.admob, placement))
                if adValue.value == 0 {
                    LogEventManager.shared.log(event: .adNoRevenue(.admob, placement))
                }
            }
            let adRevenueParams: [AnyHashable: Any] = [
                kAppsFlyerAdRevenueCountry: Locale.current.regionCodeString ?? "US",
                kAppsFlyerAdRevenueAdUnit: ad.adUnitID as Any,
                kAppsFlyerAdRevenueAdType: "AdMob_RewardedInterstitial"
            ]
            
            AppsFlyerAdRevenue.shared().logAdRevenue(
                monetizationNetwork: "admob",
                mediationNetwork: MediationNetworkType.googleAdMob,
                eventRevenue: adValue.value,
                revenueCurrency: adValue.currencyCode,
                additionalParameters: adRevenueParams)
        }
    }
    
    private func onLoadAdSuccess(_ ad: RewardedInterstitialAd) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Did load! (\(String(describing: name)))")
        if let name {
            let time = TimeManager.shared.end(event: .adLoad(name))
            LogEventManager.shared.log(event: .adLoadSuccess(.admob, name, time))
        }
        self.retryAttempt = 0
        self.rewardedInterstitialAd = ad
        self.rewardedInterstitialAd?.fullScreenContentDelegate = self
        Task { @MainActor in
            self.didLoadSuccess?()
        }
        
        let network = ad.responseInfo.adNetworkInfoArray.first
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Adapter(\(String(describing: network)))!")
        
        onListeringPaidEvent(ad)
    }
}
