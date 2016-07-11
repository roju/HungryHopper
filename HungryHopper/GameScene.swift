//
//  GameScene.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/8/16.
//  Copyright (c) 2016 Ross Justin. All rights reserved.
//

import SpriteKit

var hero:SKSpriteNode!
var isTouching = false;
let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
var enemyTimer: CFTimeInterval = 0
let enemyDelaySeconds:CFTimeInterval = 0.01
var enemies = Set<Enemy>()

class GameScene: SKScene {
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        hero = self.childNodeWithName("//hero") as! SKSpriteNode
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = true
        
        //hero.physicsBody?.applyImpulse(CGVectorMake(0, 50))
        
        /*
        for touch in touches {
            
        }
         */
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = false
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        
        if isTouching {
            hero.physicsBody!.applyImpulse(CGVectorMake(0, 2))
        }
        
        if enemyTimer >= enemyDelaySeconds {
            addEnemy()
            enemyTimer = 0
        }
        
        moveEnemies()
        
        for enemy in enemies {
            if enemy.position.x > 500 || enemy.position.x < -100{
                enemies.remove(enemy)
                enemy.removeFromParent()
            }
        }
        
        enemyTimer += fixedDelta
        
        if hero.position.x > 320.0 / 2 {
            hero.position.x = 320.0 / 2
        }
        else if hero.position.x < 320.0 / 2 {
            hero.position.x = 320.0 / 2
        }
    }
    
    func addEnemy(){
        let resourcePath = NSBundle.mainBundle().pathForResource("Enemy", ofType: "sks")
        let enemy = Enemy(URL: NSURL (fileURLWithPath: resourcePath!))
        var enemyPositionX = -100
        
        
        if arc4random_uniform(11) > 5 { // random 50%
            enemyPositionX = 320 + 100
            enemy.direction = .Left
        }
        
        enemy.position = CGPoint(x: enemyPositionX, y:Int(arc4random() % 480))
        
        addChild(enemy)
        enemies.insert(enemy)
    }
    
    func moveEnemies(){
        for enemy in enemies{
            var speed = 5
            if enemy.direction == .Left {
                speed = -speed
            }
            
            let move = SKAction.moveBy(CGVector(dx: speed, dy: 0), duration: 0.5)
            enemy.runAction(move)
        }
    }
}
