//
//  MonetizationNetwork.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 05/08/2024.
//

import Foundation

public enum MonetizationNetwork: String, Codable {
  case admob
  case max
  
  var name: String {
    switch self {
    case .admob:
      return "admob"
    case .max:
      return "max"
    }
  }
}
