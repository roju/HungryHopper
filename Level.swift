//
//  StageTimer.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/20/16.
//  Copyright © 2016 Ross Jusrin. All rights reserved.
//

import Foundation
import SpriteKit

class Level {
    var timerCounter:CFTimeInterval
    var timerDelayValue:CFTimeInterval
    var yPosition:Int
    var rectDimensions:CGSize
    var direction:MovingDirection
    var speed:CGFloat
    var initialSpeed:CGFloat
    var initialTimerDelayValue:CFTimeInterval
    var fillsX:Bool
    var levelID:String
    
    init (timerDelayValue:CFTimeInterval, yPosition:Int, rectDimensions:CGSize, direction:MovingDirection, speed:CGFloat, levelID:String) {
        self.timerCounter = 0.0
        self.timerDelayValue = timerDelayValue
        self.initialTimerDelayValue = timerDelayValue
        self.yPosition = yPosition
        self.rectDimensions = rectDimensions
        self.direction = direction
        self.speed = speed
        self.initialSpeed = speed
        self.fillsX = false
        self.levelID = levelID
    }
}