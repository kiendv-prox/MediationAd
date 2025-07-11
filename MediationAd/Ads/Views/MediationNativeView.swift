//
//  MediationNativeView.swift
//  MediationAd
//
//  Created by Dev_iOS on 8/7/25.
//

import UIKit

public protocol AdMobNativeAdProperty {
    func load(placement: String, didReceive: Handler?, didError: Handler?)
}

public typealias MediationAdMobNativeView = AdMobNativeAdView & AdMobNativeAdProperty
public typealias MediationMaxNativeView = MaxNativeAdView & AdMobNativeAdProperty

public class MediationNativeView: UIView {
    private var admobNativeView: MediationAdMobNativeView?
    private var maxNativeView: MediationMaxNativeView?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setComponents()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setComponents()
    }
    
    public override func removeFromSuperview() {
        admobNativeView?.removeFromSuperview()
        admobNativeView = nil
        maxNativeView?.removeFromSuperview()
        maxNativeView = nil
        super.removeFromSuperview()
    }
    
    private func setComponents() {
        backgroundColor = .clear
    }
}

extension MediationNativeView {
    @MainActor
    public func load(placement: String,
                     admobView: MediationAdMobNativeView,
                     maxView: MediationMaxNativeView,
                     didReceive: Handler? = nil,
                     didError: Handler? = nil) {
        guard let network = networkAd(placement: placement),
                statusAd(placement: placement) else {
            didError?()
            return
        }
        registerNativeView(admobView: admobView,
                           maxView: maxView,
                           network: network)
        loadAdWithNativeView(placement: placement, network: network, didReceive: didReceive, didError: didError)
    }
    
    private func networkAd(placement: String) -> MonetizationNetwork? {
        AdManager.shared.network(type: .onceUsed(.native), placement: placement)
    }
    
    private func statusAd(placement: String) -> Bool {
        AdManager.shared.status(type: .onceUsed(.native), placement: placement) ?? true
    }
}

extension MediationNativeView {
    private func registerNativeView(admobView: MediationAdMobNativeView,
                                    maxView: MediationMaxNativeView,
                                    network: MonetizationNetwork) {
        switch network {
        case .admob:
            guard admobNativeView == nil else { return }
            maxNativeView?.removeFromSuperview()
            maxNativeView = nil
            admobNativeView = admobView
            admobNativeView?.frame = frame
            addSubviewFitSuperView(admobNativeView!)
        case .max:
            guard maxNativeView == nil else { return }
            admobNativeView?.removeFromSuperview()
            admobNativeView = nil
            maxNativeView = maxView
            maxNativeView?.frame = frame
            addSubviewFitSuperView(maxNativeView!)
        }
    }
    
    private func loadAdWithNativeView(placement: String,
                                      network: MonetizationNetwork,
                                      didReceive: Handler?,
                                      didError: Handler?) {
        switch network {
        case .admob:
            admobNativeView?.load(placement: placement, didReceive: didReceive, didError: didError)
        case .max:
            maxNativeView?.load(placement: placement, didReceive: didReceive, didError: didError)
        }
    }
}
