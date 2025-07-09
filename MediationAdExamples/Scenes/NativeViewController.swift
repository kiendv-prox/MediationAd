//
//  NativeViewController.swift
//  AdmobLibraryDemo
//
//  Created by Trịnh Xuân Minh on 05/12/2022.
//

import UIKit
import MediationAd

class NativeViewController: BaseViewController {
    @IBOutlet weak var nativeAdView: MediationNativeView!
    
    override func setProperties() {
        nativeAdView.isHidden = false
        nativeAdView.load(placement: AppText.AdName.native,
                          admobView: CustomAdMobNativeAdView(),
                          maxView: CustomMaxNativeAdView(),
                          didError: { [weak self] in
            guard let self else { return }
            Task {@MainActor in
                self.nativeAdView.isHidden = true
            }
        })
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.pop(animated: true)
    }
}
