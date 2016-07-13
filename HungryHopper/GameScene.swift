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
        
        hero.hero.physicsBody?.velocity = CGVectorMake(0, 0)
        hero.hero.physicsBody?.applyImpulse(CGVectorMake(0, 8))
        
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
            //hero.hero.physicsBody!.applyImpulse(CGVectorMake(0, 1))
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
        
        // keep hero centered in X
        
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
        
        let randomSpeed = randomBetweenNumbers(0.5, secondNum: 2)
        enemy.movementSpeed = randomSpeed
        
        var enemyPositionX:CGFloat = -100
        
        if arc4random_uniform(11) > 5 { // random 50%
            enemyPositionX = screenWidth + 100
            enemyReferenceNode.enemySprite.direction = .Left
            enemy.movementSpeed = -enemy.movementSpeed
        }
        
        let randomSize = randomBetweenNumbers(0.4, secondNum: 3)
        enemy.setScale(randomSize)
        enemy.sizeValue = randomSize
        
        enemy.position = CGPoint(x:enemyPositionX, y:randomBetweenNumbers(0, secondNum: screenHeight))
        
        addChild(enemyReferenceNode)
        enemies.insert(enemy)
    }
    
    func moveEnemies(){
        for enemy in enemies{
            let move = SKAction.moveBy(CGVector(dx: enemy.movementSpeed, dy: 0), duration: 0.5)
            enemy.runAction(move)
        }
    }
    
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        //print("contact")
        
        func runContactActions(hero:Hero, enemy:Enemy){
            //print("enemy size: \(enemy.sizeValue)")
            //print("hero size: \(hero.sizeValue)")
            
            if hero.sizeValue > enemy.sizeValue {
                enemies.remove(enemy)
                enemy.removeFromParent()
                hero.sizeValue += 0.05
                hero.runAction(SKAction.scaleTo(hero.sizeValue, duration: 0.2))
            }
            else{
                print("DEAD")
            }
        }
        
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if (nodeA.name == "hero" && nodeB.name == "enemy"){
            runContactActions(nodeA as! Hero, enemy: nodeB as! Enemy)
        }
        
        // doesn't seem to run, here just in case
        else if (nodeA.name == "enemy" && nodeB.name == "hero") {
            runContactActions(nodeB as! Hero, enemy: nodeA as! Enemy)
        }
    }
}
