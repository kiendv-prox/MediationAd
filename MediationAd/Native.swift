//
//  Native.swift
//  
//
//  Created by Trịnh Xuân Minh on 23/08/2023.
//

import Foundation

struct Native: AdConfigProtocol {
  let placement: String
  let status: Bool
  let name: String
  let ads_type: MonetizationNetwork
  let id_ads: AdIds?
  let isAuto: Bool?
  let description: String?
  let isFullScreen: Bool?
  let isPreload: Bool?
  let timeout: Double?
}
