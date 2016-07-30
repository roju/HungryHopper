//
//  Obstacle.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/20/16.
//  Copyright © 2016 Ross Jusrin. All rights reserved.
//

import Foundation
import SpriteKit

class Obstacle:SKShapeNode {
    var direction:MovingDirection = .Right
    var movementSpeedX:CGFloat = 1
    var movementSpeedY:CGFloat = 0
    var levelID:String = ""
    var flaggedForRemoval = false
    var rotationAngle:CGFloat = 0.0
    
    override init() {
        super.init()
        self.fillColor = UIColor.blackColor()
    }
    
    init(rect:CGRect){
        super.init()
        self.fillColor = UIColor.blackColor()
        self.path = CGPathCreateWithRect(rect, nil)
    }
    
    init(rect:CGRect, rotation:CGFloat){
        super.init()
        self.fillColor = UIColor.blackColor()
        self.path = CGPathCreateWithRect(rect, nil)
        self.rotationAngle = rotation
        self.zRotation = rotation
    }
    
    init(circleOfRadius: CGFloat){
        super.init()
        self.fillColor = UIColor.blackColor()
        let diameter = circleOfRadius * 2
        self.path = CGPathCreateWithEllipseInRect(CGRect(origin: CGPointZero, size: CGSize(width: diameter, height: diameter)), nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}