//
//  Enemy.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/11/16.
//  Copyright © 2016 Ross Justin. All rights reserved.
//

import Foundation
import SpriteKit

enum MovingDirection {
    case Left, Right
}

class Enemy: SKReferenceNode {
    var enemySprite:SKSpriteNode!
    var direction:MovingDirection = .Right
    
    override func didLoadReferenceNode(node: SKNode?) {
        enemySprite = childNodeWithName("//enemy") as! SKSpriteNode
    }
}