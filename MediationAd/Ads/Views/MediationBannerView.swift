//
//  MediationBannerView.swift
//  MediationAd
//
//  Created by Dev_iOS on 7/7/25.
//

import UIKit

public class MediationBannerView: UIView {
  private var admobBannerView: AdMobBannerAdView?
  private var maxBannerView: MaxBannerAdView?
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    
    setComponents()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    setComponents()
  }
  
  public override func removeFromSuperview() {
    admobBannerView = nil
    maxBannerView = nil
    super.removeFromSuperview()
  }
  
  private func setComponents() {
    backgroundColor = .clear
  }
}

extension MediationBannerView {
  @MainActor
  public func load(placement: String,
                   rootViewController: UIViewController,
                   didReceive: Handler? = nil,
                   didError: Handler? = nil) {
    guard let network = networkAd(placement: placement), statusAd(placement: placement) else {
      didError?()
      return
    }
    registerBannerView(network)
    loadAdWithBannerView(placement: placement,
                         network: network,
                         rootViewController: rootViewController,
                         didReceive: didReceive, didError: didError)
  }
  
  private func networkAd(placement: String) -> MonetizationNetwork? {
    AdManager.shared.network(type: .onceUsed(.banner), placement: placement)
  }
  
  private func statusAd(placement: String) -> Bool {
    AdManager.shared.status(type: .onceUsed(.banner), placement: placement) ?? true
  }
  
  private func registerBannerView(_ network: MonetizationNetwork) {
    switch network {
    case .admob:
      guard admobBannerView == nil else { return }
      maxBannerView = nil
      subviews.forEach({ $0.removeFromSuperview() })
      admobBannerView = .init(frame: self.frame)
      addSubviewFitSuperView(admobBannerView!)
    case .max:
      guard maxBannerView == nil else { return }
      admobBannerView = nil
      subviews.forEach({ $0.removeFromSuperview() })
      let size = CGSize(width: 320, height: 50)
      let offsetX = (frame.width - size.width)/4 ///
      let offsetY = (frame.height - size.height)/2
      let origin: CGPoint = .init(x: offsetX, y: offsetY)
      maxBannerView = .init(frame: .init(origin: origin, size: size))
      
      addSubview(maxBannerView!, constraints: [
        maxBannerView!.centerXAnchor.constraint(equalTo: centerXAnchor),
        maxBannerView!.centerYAnchor.constraint(equalTo: centerYAnchor),
        maxBannerView!.heightAnchor.constraint(equalToConstant: size.height),
        maxBannerView!.widthAnchor.constraint(equalToConstant: size.width)
      ])
    }
  }
  
  private func loadAdWithBannerView(placement: String,
                                    network: MonetizationNetwork,
                                    rootViewController: UIViewController,
                                    didReceive: Handler?,
                                    didError: Handler?) {
    switch network {
    case .admob:
      admobBannerView?.load(placement: placement,
                            rootViewController: rootViewController,
                            didReceive: didReceive,
                            didError: didError)
    case .max:
      maxBannerView?.load(placement: placement,
                          rootViewController: rootViewController,
                          didReceive: didReceive,
                          didError: didError)
    }
  }
}
