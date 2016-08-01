//
//  Enemy.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/12/16.
//  Copyright © 2016 Ross Jusrin. All rights reserved.
//

import Foundation
import SpriteKit

class Enemy:SKSpriteNode {
    var direction:MovingDirection = .Right
    var sizeValue:CGFloat = 1
    var movementSpeedX:CGFloat = 1
    var movementSpeedY:CGFloat = 0
    var levelID:String = ""
    var flaggedForRemoval = false
    
    override init(texture: SKTexture?, color: UIColor, size:CGSize){
        super.init(texture: texture, color: UIColor.clearColor(), size: texture!.size())
        
    }
    
    required init (coder aDecoder: NSCoder){
        super.init(coder:aDecoder)!
        userInteractionEnabled = false
    }
}