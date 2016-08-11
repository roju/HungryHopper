//
//  HighScore.swift
//  HungryHopper
//
//  Created by Ross Justin on 8/1/16.
//  Copyright © 2016 Ross Jusrin. All rights reserved.
//

import Foundation

class Singletons {
    var highScore = 0
    var bestCombo = 0
    var totalCoins = 0
    
    static let sharedInstance = Singletons()
    private init() {} //This prevents others from using the default '()' initializer for this class.
}