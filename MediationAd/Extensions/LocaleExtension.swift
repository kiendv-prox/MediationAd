//
//  LocaleExtension.swift
//  MediationAd
//
//  Created by Dev_iOS on 25/6/25.
//

import Foundation

extension Locale {
    var regionCodeString: String? {
        if #available(iOS 16, *) {
            return region?.identifier.uppercased()
        } else {
            return regionCode?.uppercased()
        }
    }
}
