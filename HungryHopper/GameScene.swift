//
//  GameScene.swift
//  HungryHopper
//
//  Created by Ross Justin on 7/8/16.
//  Copyright (c) 2016 Ross Justin. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var hero:MSReferenceNode!
    var isTouching = false;
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    var enemyTimer: CFTimeInterval = 0
    let enemyDelaySeconds:CFTimeInterval = 0.5
    var enemies = Set<Enemy>()
    let screenHeight:CGFloat = 480.0
    let screenWidth:CGFloat = 320.0
    
    override func didMoveToView(view: SKView) {
        let resourcePath = NSBundle.mainBundle().pathForResource("Hero", ofType: "sks")
        hero = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
        
        hero.hero.position = CGPoint(x: screenWidth/2, y:screenHeight/2)
        addChild(hero)
        
        physicsWorld.contactDelegate = self
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
            hero.hero.physicsBody!.applyImpulse(CGVectorMake(0, 5))
        }
        
        if enemyTimer >= enemyDelaySeconds {
            addEnemy()
            enemyTimer = 0
        }
        
        moveEnemies()
        
        for enemy in enemies {
            if (enemy.direction == .Right && enemy.position.x > screenWidth + 200) ||
                (enemy.direction == .Left && enemy.position.x < -200) {
                
                //print("removed enemy at: \(enemy.position.x)")
                enemies.remove(enemy)
                enemy.removeFromParent()
            }
        }
        
        enemyTimer += fixedDelta
        
        if hero.hero.position.x > screenWidth / 2 {
            hero.hero.position.x = screenWidth / 2
        }
        else if hero.hero.position.x < screenWidth / 2 {
            hero.hero.position.x = screenWidth / 2
        }
    }
    
    func addEnemy(){
        let resourcePath = NSBundle.mainBundle().pathForResource("Enemy", ofType: "sks")
        let enemyReferenceNode = EnemyReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
        let enemy = enemyReferenceNode.enemySprite
        
        var enemyPositionX:CGFloat = -100
        
        if arc4random_uniform(11) > 5 { // random 50%
            enemyPositionX = screenWidth + 100
            enemyReferenceNode.enemySprite.direction = .Left
        }
        
        let randomSize = randomBetweenNumbers(1, secondNum: 5)
        enemy.setScale(randomSize)
        enemy.sizeValue = randomSize
        
        enemy.position = CGPoint(x:enemyPositionX, y:randomBetweenNumbers(0, secondNum: screenHeight))
        
        addChild(enemyReferenceNode)
        enemies.insert(enemy)
    }
    
    func moveEnemies(){
        for enemy in enemies{
            var speed = 2
            if enemy.direction == .Left {
                speed = -speed
            }
            
            let move = SKAction.moveBy(CGVector(dx: speed, dy: 0), duration: 0.5)
            enemy.runAction(move)
        }
    }
    
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        //print("contact")
        
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if (nodeA.name == "hero" && nodeB.name == "enemy"){
            print("hero contacted enemy")
            
            if let enemy = nodeB as? Enemy {
                print("enemy size: \(enemy.sizeValue)")
                enemies.remove(enemy)
                enemy.removeFromParent()
            }
        }
        else if (nodeA.name == "enemy" && nodeB.name == "hero") {
            print("enemy contacted hero")
            
            if let enemy = contact.bodyA.node as? Enemy {
                print("enemy size: \(enemy.sizeValue)")
                enemies.remove(enemy)
                enemy.removeFromParent()
            }
        }
    }
}
