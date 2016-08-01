//
//  HighScore.swift
//  HungryHopper
//
//  Created by Ross Justin on 8/1/16.
//  Copyright © 2016 Ross Jusrin. All rights reserved.
//

import Foundation

class HighScore {
    var highScore = 0
    
    static let sharedInstance = HighScore()
    private init() {} //This prevents others from using the default '()' initializer for this class.
}