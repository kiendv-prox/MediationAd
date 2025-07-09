//
//  AdConfigProtocol.swift
//
//
//  Created by Trịnh Xuân Minh on 15/11/2023.
//

import Foundation

protocol AdConfigProtocol: Codable {
    var placement: String { get }
    var status: Bool { get }
    var name: String { get }
    var isAuto: Bool? { get }
    var network: MonetizationNetwork { get }
    var id_ads: AdIds? { get }
    var description: String? { get }
}

extension AdConfigProtocol {
    func getAdId() -> String? {
        switch network {
        case .admob: return id_ads?.idAdmob
        case .max: return id_ads?.idMax
        }
    }
}

struct AdIds: Codable {
    var idAdmob: String?
    var idMax: String?
    
    enum CodingKeys: String, CodingKey {
        case idAdmob = "id_admob"
        case idMax = "id_max"
    }
}
