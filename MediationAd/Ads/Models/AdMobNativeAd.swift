//
//  NativeAd.swift
//  AdManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

class AdMobNativeAd: NSObject, @preconcurrency OnceUsedAdProtocol, @unchecked Sendable {
    enum State {
        case wait
        case loading
        case receive
        case error
    }
    
    private var nativeAd: NativeAd?
    private var adLoader: AdLoader?
    private weak var rootViewController: UIViewController?
    private var adUnitID: String?
    private var placement: String?
    private var isFullScreen = false
    private var timeout: Double?
    private var state: State = .wait
    private var didReceive: Handler?
    private var didError: Handler?
    private var timeoutTimer: Timer?
    
    @MainActor
    func config(ad: Native, rootViewController: UIViewController?, into nativeAdView: UIView?) {
        self.rootViewController = rootViewController
        guard ad.status else {
            return
        }
        guard adUnitID == nil, let id = ad.getAdId() else {
            return
        }
        self.adUnitID = id
        self.placement = ad.placement
        self.timeout = ad.timeout
        if let isFullScreen = ad.isFullScreen {
            self.isFullScreen = isFullScreen
        }
        self.load()
    }
    
    func getState() -> State {
        return state
    }
    
    func getAd() -> NativeAd? {
        return nativeAd
    }
    
    func bind(didReceive: Handler?, didError: Handler?) {
        self.didReceive = didReceive
        self.didError = didError
    }
}

extension AdMobNativeAd: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader,
                  didFailToReceiveAdWithError error: Error) {
        guard state == .loading else {
            return
        }
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [NativeAd] Load fail (\(String(describing: placement))) - \(String(describing: error))!")
        if let placement {
            LogEventManager.shared.log(event: .adLoadFail(.admob, placement, error))
        }
        self.state = .error
        didError?()
    }
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard state == .loading else {
            return
        }
        
        onLoadAdSuccess(nativeAd, loader: adLoader)
    }
}

extension AdMobNativeAd {
    private func load() {
        guard state == .wait else {
            return
        }
        
        Task { @MainActor in
            guard let adUnitID else {
                AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [NativeAd] Failed to load - not initialized yet! Please install ID.")
                return
            }
            
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [NativeAd] Start load! (\(String(describing: placement)))")
            self.state = .loading
            
            loadNativeAd(adUnitID)
            
            registerTimeout()
        }
    }
}

extension AdMobNativeAd {
    @MainActor
    private func loadNativeAd(_ id: String) {
        var options: [GADAdLoaderOptions]? = nil
        if isFullScreen {
            let aspectRatioOption = NativeAdMediaAdLoaderOptions()
            aspectRatioOption.mediaAspectRatio = .portrait
            options = [aspectRatioOption]
        }
        adLoader = AdLoader(adUnitID: id,
                            rootViewController: rootViewController,
                            adTypes: [.native],
                            options: options)
        adLoader?.delegate = self
        
        let request = Request()
        adLoader?.load(request)
    }
    
    private func onListerningPaidEvent(_ id: String, ad: NativeAd) {
        ad.paidEventHandler = { [weak self] adValue in
            guard let self else {
                return
            }
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [NativeAd] Did pay revenue(\(adValue.value))!")
            if let placement = self.placement {
                LogEventManager.shared.log(event: .adPayRevenue(.admob, placement))
                if adValue.value == 0 {
                    LogEventManager.shared.log(event: .adNoRevenue(.admob, placement))
                }
            }
            let adRevenueParams: [AnyHashable: Any] = [
                kAppsFlyerAdRevenueCountry: Locale.current.regionCodeString ?? "US",
                kAppsFlyerAdRevenueAdUnit: id as Any,
                kAppsFlyerAdRevenueAdType: "AdMob_Native"
            ]
            
            AppsFlyerAdRevenue.shared().logAdRevenue(
                monetizationNetwork: "admob",
                mediationNetwork: MediationNetworkType.googleAdMob,
                eventRevenue: adValue.value,
                revenueCurrency: adValue.currencyCode,
                additionalParameters: adRevenueParams)
        }
    }
    
    private func onLoadAdSuccess(_ ad: NativeAd, loader: AdLoader) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [NativeAd] Did load! (\(String(describing: placement)))")
        if let placement {
            let time = TimeManager.shared.end(event: .adLoad(placement))
            LogEventManager.shared.log(event: .adLoadSuccess(.admob, placement, time))
        }
        self.state = .receive
        self.nativeAd = ad
        Task { @MainActor in
            didReceive?()
        }
        
        let network = ad.responseInfo.adNetworkInfoArray.first
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [NativeAd] Adapter(\(String(describing: network)))!")
        
        
        onListerningPaidEvent(loader.adUnitID, ad: ad)
    }
}

extension AdMobNativeAd {
    private func registerTimeout() {
        guard let timeout, timeoutTimer == nil else { return }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            
            guard state == .loading else {
                unregisterTimeout()
                return
            }
            
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [NativeAd] Load fail (\(String(describing: placement))) - time out!")
            if let placement {
                LogEventManager.shared.log(event: .adLoadTimeout(.admob, placement))
            }
            self.state = .error
            
            Task { @MainActor in
                self.didError?()
            }
            
            unregisterTimeout()
        })
    }
    
    private func unregisterTimeout() {
        guard timeoutTimer != nil else {return}
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}
