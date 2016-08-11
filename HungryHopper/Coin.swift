//
//  Coin.swift
//  HungryHopper
//
//  Created by Ross Justin on 8/8/16.
//  Copyright © 2016 Ross Jusrin. All rights reserved.
//

import Foundation
import SpriteKit

class Coin:SKSpriteNode {
    var collected = false
    var parentCollectible:Collectible?
}