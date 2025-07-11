//
//  RewardedAd.swift
//  
//
//  Created by Trịnh Xuân Minh on 02/12/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

class AdMobRewardedAd: NSObject, @preconcurrency ReuseAdProtocol, @unchecked Sendable {
    private var rewardedAd: RewardedAd?
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
        return rewardedAd != nil
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
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Display failure - ads are being displayed! (\(placement))")
            didFail?()
            return
        }
        
        LogEventManager.shared.log(event: .adShowRequest(.admob, placement))
        guard isReady() else {
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Display failure - not ready to show! (\(placement))")
            LogEventManager.shared.log(event: .adShowNoReady(.admob, placement))
            didFail?()
            return
        }
        
        LogEventManager.shared.log(event: .adShowReady(.admob, placement))
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Requested to show! (\(placement))")
        
        self.placement = placement
        self.didShowFail = didFail
        self.willPresent = willPresent
        self.didHide = didHide
        self.didEarnReward = didEarnReward
        
        Task { @MainActor in
            rewardedAd?.present(from: rootViewController, userDidEarnRewardHandler: { [weak self] in
                guard let self else { return }
                LogEventManager.shared.log(event: .adEarnReward(.admob, placement))
                self.didEarnReward?()
            })
        }
    }
}

extension AdMobRewardedAd: FullScreenContentDelegate {
    func ad(_ ad: FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error
    ) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Did fail to show content! (\(String(describing: name)))")
        if let placement {
            LogEventManager.shared.log(event: .adShowFail(.admob, placement, error))
        }
        didShowFail?()
        self.rewardedAd = nil
        load()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Will display! (\(String(describing: name)))")
        if let placement {
            LogEventManager.shared.log(event: .adShowSuccess(.admob, placement))
        }
        willPresent?()
        self.presentState = true
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Did hide! (\(String(describing: name)))")
        if let placement {
            LogEventManager.shared.log(event: .adShowHide(.admob, placement))
        }
        didHide?()
        self.rewardedAd = nil
        self.presentState = false
        load()
    }
}

extension AdMobRewardedAd {
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
                AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Failed to load - not initialized yet! Please install ID.")
                return
            }
            
            isLoading = true
            
            do {
                let ad = try await loadRewardedAd(adUnitID)
                isLoading = false
                onLoadAdSuccess(ad)
            } catch {
                isLoading = false
                AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Load fail (\(String(describing: name))) - \(String(describing: error))!")
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

extension AdMobRewardedAd {
    private func loadRewardedAd(_ id: String) async throws -> RewardedAd {
        let request = Request()
        return try await RewardedAd.load(with: id, request: request)
    }
    
    private func onListerningPaidEvent(_ ad: RewardedAd) {
        ad.paidEventHandler = { adValue in
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Did pay revenue(\(adValue.value))!")
            if let placement = self.placement {
                LogEventManager.shared.log(event: .adPayRevenue(.admob, placement))
                if adValue.value == 0 {
                    LogEventManager.shared.log(event: .adNoRevenue(.admob, placement))
                }
            }
            
            let adRevenueParams: [AnyHashable: Any] = [
                kAppsFlyerAdRevenueCountry: Locale.current.regionCodeString ?? "US",
                kAppsFlyerAdRevenueAdUnit: ad.adUnitID as Any,
                kAppsFlyerAdRevenueAdType: "AdMob_Rewarded"
            ]
            
            AppsFlyerAdRevenue.shared().logAdRevenue(
                monetizationNetwork: "admob",
                mediationNetwork: MediationNetworkType.googleAdMob,
                eventRevenue: adValue.value,
                revenueCurrency: adValue.currencyCode,
                additionalParameters: adRevenueParams)
        }
    }
    
    private func onLoadAdSuccess(_ ad: RewardedAd) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Did load! (\(String(describing: name)))")
        
        if let name {
            let time = TimeManager.shared.end(event: .adLoad(name))
            LogEventManager.shared.log(event: .adLoadSuccess(.admob, name, time))
        }
        
        self.retryAttempt = 0
        self.rewardedAd = ad
        self.rewardedAd?.fullScreenContentDelegate = self
        Task { @MainActor in
            self.didLoadSuccess?()
        }
        
        let network = ad.responseInfo.adNetworkInfoArray.first
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [RewardAd] Adapter(\(String(describing: network)))!")
        
        onListerningPaidEvent(ad)
    }
}
