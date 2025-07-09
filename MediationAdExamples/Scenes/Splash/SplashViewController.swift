//
//  SplashViewController.swift
//  AdmobLibraryDemo
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import MediationAd
import Combine

class SplashViewController: BaseViewController {
  override func binding() {
      AppManager.shared.$adConfigStatus
          .filter({ $0 }).first()
          .sink(receiveValue: { [weak self] status in
              guard let self else { return }
              AdManager.shared.load(type: .splash, placement: AppText.AdName.splash, success: {
                  self.showAds()
              }, fail: {
                  self.toHome()
              })
              AdManager.shared.load(type: .interstitial, placement: AppText.AdName.interstitial)
              AdManager.shared.load(type: .appOpen, placement: AppText.AdName.appOpen)
              AdManager.shared.load(type: .rewarded, placement: AppText.AdName.rewarded)
              AdManager.shared.load(type: .rewardedInterstitial, placement: AppText.AdName.rewardedInterstitial)
          })
          .store(in: &subscriptions)
      
      AppManager.shared.$configStatus
          .filter({ $0 })
          .first()
          .receive(on: DispatchQueue.main)
          .sink {[weak self] _ in
              guard let self, !AppManager.shared.adConfigStatus else { return }
              self.toHome()
          }
          .store(in: &subscriptions)
      
//    AdManager.shared.$registerState
//      .receive(on: DispatchQueue.main)
//      .sink { [weak self] state in
//        guard let self else {
//          return
//        }
//        switch state {
//        case .success, .error:
//          
////          AdManager.shared.preloadNative(name: AppText.AdName.native, into: CustomMaxNativeAdView().nativeAdView)
//        case .reject, .premium:
//          self.toHome()
//        case .wait:
//          break
//        }
//      }.store(in: &subscriptions)
  }
  
  func showAds() {
    AdManager.shared.show(type: .splash,
                          placement: AppText.AdName.splash,
                          rootViewController: self,
                          didFail: toHome,
                          didHide: toHome)
  }
  
  func toHome() {
      Task { @MainActor in
          self.push(to: HomeViewController(), animated: false)
      }
  }
}
