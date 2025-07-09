//
//  UIViewExtension.swift
//  MediationAd
//
//  Created by Dev_iOS on 24/6/25.
//

import UIKit

extension UIView {
    func addSubview(_ subview: UIView, constraints: [NSLayoutConstraint]) {
        addSubview(subview)
        NSLayoutConstraint.activate(constraints)
    }
    
    func addSubviewFitSuperView(_ subview: UIView) {
        addSubview(subview, constraints: [
            subview.leadingAnchor.constraint(equalTo: leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor),
            subview.topAnchor.constraint(equalTo: topAnchor),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
