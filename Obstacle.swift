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
    var movementSpeed:CGFloat = 1
    var initialMovementSpeed:CGFloat = 1
    var levelID:String = ""
    var flaggedForRemoval = false
    
    override init() {
        super.init()
        self.fillColor = UIColor.blackColor()
    }
    
    init(rect:CGRect){
        super.init()
        self.fillColor = UIColor.blackColor()
        self.path = CGPathCreateWithRect(rect, nil)
    }
    
    init(circleOfRadius: CGFloat){
        super.init()
        self.fillColor = UIColor.blackColor()
        let diameter = circleOfRadius * 2
        self.path = CGPathCreateWithEllipseInRect(CGRect(origin: CGPointZero, size: CGSize(width: diameter, height: diameter)), nil)
    }
    /*
    func modifyRect(width:CGFloat, height:CGFloat) {
        self.runAction(SKAction.scaleXTo(width, duration: 0))
        self.runAction(SKAction.scaleYTo(height, duration: 0))
    }
    */
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}