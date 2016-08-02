//
//  Collectible.swift
//  HungryHopper
//
//  Created by Ross Justin on 8/2/16.
//  Copyright © 2016 Ross Jusrin. All rights reserved.
//

import Foundation
import SpriteKit

class Collectible:SKSpriteNode {
    var type = 0
    var flaggedForRemoval = false
    
    override init(texture: SKTexture?, color: UIColor, size:CGSize){
        super.init(texture: texture, color: UIColor.clearColor(), size: texture!.size())
    }
    
    required init (coder aDecoder: NSCoder){
        super.init(coder:aDecoder)!
        userInteractionEnabled = false
    }
}