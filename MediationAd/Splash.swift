//
//  Splash.swift
//  
//
//  Created by Trịnh Xuân Minh on 06/09/2023.
//

import Foundation

struct Splash: AdConfigProtocol {
  let placement: String
  let status: Bool
  let name: String
  let ads_type: MonetizationNetwork
  let id_ads: AdIds?
  let isAuto: Bool?
  let description: String?
  let timeout: Double
}
