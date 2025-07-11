//
//  AdMobBannerView.swift
//  AdManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

open class AdMobBannerAdView: UIView, @unchecked Sendable {
    enum State {
        case wait
        case loading
        case receive
        case error
    }
    
    private lazy var bannerAdView: BannerView! = {
        let bannerView = BannerView()
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        return bannerView
    }()
    
    public enum Anchored: String {
        case top
        case bottom
    }
    
    private weak var rootViewController: UIViewController?
    private var adUnitID: String?
    private var placement: String?
    private var anchored: Anchored?
    private var state: State = .wait
    private var didReceive: Handler?
    private var didError: Handler?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addComponents()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        addComponents()
    }
    
    public override func removeFromSuperview() {
        self.bannerAdView = nil
        super.removeFromSuperview()
    }
    
    @MainActor
    public func load(placement: String,
                     rootViewController: UIViewController,
                     didReceive: Handler?,
                     didError: Handler?
    ) {
        self.didReceive = didReceive
        self.didError = didError
        self.rootViewController = rootViewController
        
        guard adUnitID == nil else {
            return
        }
        switch AdManager.shared.status(type: .onceUsed(.banner), placement: placement) {
        case false:
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [BannerAd] Ads are not allowed to show! (\(placement))")
            errored()
            return
        case true:
            break
        default:
            errored()
            return
        }
        guard let ad = AdManager.shared.getAd(type: .onceUsed(.banner), placement: placement) as? Banner else {
            return
        }
      
        guard ad.status, let id = ad.getAdId() else {
            return
        }
        self.adUnitID = id
        self.placement = ad.placement
        if let anchored = ad.anchored {
            self.anchored = Anchored(rawValue: anchored)
        }
        load()
    }
}

extension AdMobBannerAdView: BannerViewDelegate {
    public func bannerView(_ bannerView: BannerView,
                           didFailToReceiveAdWithError error: Error
    ) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [BannerAd] Load fail (\(String(describing: placement))) - \(String(describing: error))!")
        if let placement {
            LogEventManager.shared.log(event: .adLoadFail(.admob, placement, error))
        }
        self.state = .error
        errored()
    }
    
    public func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [BannerAd] Did load! (\(String(describing: placement)))")
        if let placement {
            let time = TimeManager.shared.end(event: .adLoad(placement))
            LogEventManager.shared.log(event: .adLoadSuccess(.admob, placement, time))
        }
        self.state = .receive
        bringSubviewToFront(self.bannerAdView)
        didReceive?()
        
        let network = bannerAdView.responseInfo?.adNetworkInfoArray.first
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [BannerAd] Adapter(\(String(describing: network)))!")
        
        onListerningPaidEvent(bannerView)
    }
}

extension AdMobBannerAdView {
    private func addComponents() {
        addSubviewFitSuperView(bannerAdView)
    }
    
    private func errored() {
        didError?()
    }
    
    @MainActor
    private func load() {
        guard state == .wait else {
            return
        }
        
        guard let adUnitID else {
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [BannerAd] Failed to load - not initialized yet! Please install ID.")
            return
        }
        
        AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [BannerAd] Start load! (\(String(describing: placement)))")
        self.state = .loading
        self.bannerAdView?.adUnitID = adUnitID
        self.bannerAdView?.delegate = self
        self.bannerAdView?.rootViewController = rootViewController
        
        let request = Request()
        
        if let anchored = self.anchored {
            let extras = Extras()
            extras.additionalParameters = ["collapsible": anchored.rawValue]
            request.register(extras)
        }
        
        if let placement {
            LogEventManager.shared.log(event: .adLoadRequest(.admob, placement))
            TimeManager.shared.start(event: .adLoad(placement))
        }
        self.bannerAdView?.load(request)
    }
    
    private func onListerningPaidEvent(_ adView: BannerView) {
        adView.paidEventHandler = { [weak self] adValue in
            guard let self else {
                return
            }
            AdLogManager.shared.log("[MediationAd] [AdManager] [AdMob] [BannerAd] Did pay revenue(\(adValue.value))!")
            if let placement = self.placement {
                LogEventManager.shared.log(event: .adPayRevenue(.admob, placement))
                if adValue.value == 0 {
                    LogEventManager.shared.log(event: .adNoRevenue(.admob, placement))
                }
            }
            
            let adRevenueParams: [AnyHashable: Any] = [
                kAppsFlyerAdRevenueCountry: Locale.current.regionCodeString ?? "US",
                kAppsFlyerAdRevenueAdUnit: adView.adUnitID as Any,
                kAppsFlyerAdRevenueAdType: "AdMob_Banner"
            ]
            
            AppsFlyerAdRevenue.shared().logAdRevenue(
                monetizationNetwork: "admob",
                mediationNetwork: MediationNetworkType.googleAdMob,
                eventRevenue: adValue.value,
                revenueCurrency: adValue.currencyCode,
                additionalParameters: adRevenueParams)
        }
    }
}
