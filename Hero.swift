//
//  Hero.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/12/16.
//  Copyright © 2016 Ross Jusrin. All rights reserved.
//

import Foundation
import SpriteKit

class Hero: SKSpriteNode {
    var sizeValue:CGFloat = 1
    
    override init(texture: SKTexture?, color: UIColor, size:CGSize){
        super.init(texture: texture, color: color, size: size)
    }
    
    required init (coder aDecoder: NSCoder){
        super.init(coder:aDecoder)!
        userInteractionEnabled = true
    }
}