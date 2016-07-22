//
//  Enemy.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/11/16.
//  Copyright © 2016 Ross Justin. All rights reserved.
//

import Foundation
import SpriteKit

class EnemyReferenceNode: SKReferenceNode {
    var enemySprite: Enemy!
    
    override func didLoadReferenceNode(node: SKNode?) {
        enemySprite = childNodeWithName("//enemy") as! Enemy
    }
}