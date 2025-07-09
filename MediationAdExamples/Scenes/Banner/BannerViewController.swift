//
//  BannerVC.swift
//  AdmobLibraryDemo
//
//  Created by Trịnh Xuân Minh on 06/06/2023.
//

import UIKit
import MediationAd
import SnapKit
import NVActivityIndicatorView

class BannerViewController: BaseViewController {
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var bannerAdView: MediationBannerView!
    
    override func setProperties() {
        bannerAdView.isHidden = false
        bannerAdView.load(placement: AppText.AdName.banner,
                          rootViewController: self,
                          didError: { [weak self] in
            guard let self else {
                return
            }
            Task { @MainActor in
                self.bannerAdView.isHidden = true
            }
        })
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.pop(animated: true)
    }
}
