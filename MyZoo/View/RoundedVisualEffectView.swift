//
//  RoundedLabel.swift
//  MyZoo
//
//  Created by Caleb Stultz on 8/3/18.
//  Copyright © 2018 Caleb Stultz. All rights reserved.
//

import UIKit

class RoundedVisualEffectView: UIVisualEffectView {

    override func awakeFromNib() {
        self.layer.cornerRadius = 10
        self.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMinYCorner]
        self.clipsToBounds = true
    }

}
