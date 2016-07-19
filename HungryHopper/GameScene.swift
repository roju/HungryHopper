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
    var isTouching = false
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    var enemyTimer: CFTimeInterval = 0
    let enemyDelaySeconds:CFTimeInterval = 0.1
    var enemies = Set<Enemy>()
    var background:SKSpriteNode!
    //let screenHeight:CGFloat = 480
    //let screenWidth:CGFloat = 320
    var impulseX:CGFloat = 0.0
    var impulseXContinuous:CGFloat = 0.05
    var cam:SKCameraNode!
    let gravityInWater:CGFloat = -3.0
    let gravityOutOfWater:CGFloat = -9.0
    
    override func didMoveToView(view: SKView) {
        background = childNodeWithName("background") as! SKSpriteNode
        
        let resourcePath = NSBundle.mainBundle().pathForResource("Hero", ofType: "sks")
        hero = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
        
        hero.hero.position = CGPoint(x: self.frame.width/2, y: 50)
        addChild(hero)
        
        physicsWorld.contactDelegate = self
        
        /* Camera */
        cam = SKCameraNode() //initialize and assign an instance of SKCameraNode to the cam variable.
        cam.scaleAsPoint = CGPoint(x: 2.0, y: 2.0) //the scale sets the zoom level of the camera on the given position
        
        self.camera = cam //set the scene's camera to reference cam
        self.addChild(cam) //make the cam a childElement of the scene itself.
        
        //position the camera on the gamescene.
        cam.position = hero.hero.position //CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        
        self.physicsWorld.gravity = CGVectorMake(0.0, gravityInWater);
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = true
        
        /*
        impulseX = CGRectGetMidX(self.frame)
        
        for touch in touches {
            if touch == touches.first {
                //let position = touch.locationInNode(self)
                let position = touch.locationInView(self.view)
                impulseX = position.x
                //print("raw x: \(impulseX)")
            }
        }
        
        impulseX = impulseX / self.frame.width
        impulseX *= 2
        impulseX -= 1.2
        impulseX /= 15
        */
        
        /*
        let touch = touches.first
        let position = touch!.locationInView(self.view)
        let touchX = position.x
        //print("raw x: \(touchX)")
        
        let middleOfView = (self.view!.frame.width) / 2
        if touchX > middleOfView {
            print("touching right side")
            impulseX = 0.05
        }
        else if touchX < middleOfView {
            print("touching left side")
            impulseX = -0.05
        }
        */
        
        //print("xMOD: \(impulseX)")
        
        //hero.hero.physicsBody?.velocity = CGVectorMake(0, 0)
        hero.hero.physicsBody?.applyImpulse(CGVectorMake(0, 0.8))//0.8
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Update to new touch location */
        
        /*
        for touch in touches {
            //location = touch.locationInNode(self)
            if touch == touches.first {
                //let position = touch.locationInNode(self)
                let position = touch.locationInView(self.view)
                impulseX = position.x
                //print("raw x: \(impulseX)")
                
                impulseX = impulseX / self.frame.width
                impulseX *= 2
                impulseX -= 1.2
                impulseX /= 15
            }
        }
        */
        
        /*
        let touch = touches.first
        let position = touch!.locationInView(self.view)
        let touchX = position.x
        //print("raw x: \(touchX)")
        
        let middleOfView = (self.view!.frame.width) / 2
        if touchX > middleOfView {
            //print("touching right side")
            impulseX = 0.05
        }
        else if touchX < middleOfView {
            //print("touching left side")
            impulseX = -0.05
        }
        */
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = false
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if isTouching {
            //print("xMOD: \(impulseX)")
            hero.hero.physicsBody!.applyImpulse(CGVectorMake(impulseX, 0.3))//0.3
        }
        //hero.hero.physicsBody!.applyImpulse(CGVectorMake(impulseXContinuous, 0))
        
        if hero.hero.position.y > background.frame.height {
            self.physicsWorld.gravity = CGVectorMake(0.0, gravityOutOfWater);
        }
        else{
            self.physicsWorld.gravity = CGVectorMake(0.0, gravityInWater);
        }
        
        var camPosition = hero.hero.position
        camPosition.x -= 50
        
        let moveCamToPlayer =  SKAction.moveTo(camPosition, duration: 0.1)
        cam.runAction(moveCamToPlayer)
        
        if enemyTimer >= enemyDelaySeconds {
            addRandomEnemy()
            enemyTimer = 0
        }
        
        moveEnemies()
        
        for enemy in enemies {
            if (enemy.direction == .Right && enemy.position.x > self.frame.width + 500) ||
                (enemy.direction == .Left && enemy.position.x < -500) {
                
                //print("removed enemy at: \(enemy.position.x)")
                enemies.remove(enemy)
                
                enemy.runAction(SKAction.removeFromParent())
            }
        }
        enemyTimer += fixedDelta
        
        // keep hero centered in X
        /*
        if hero.hero.position.x > screenWidth / 2 {
            hero.hero.position.x = screenWidth / 2
        }
        else if hero.hero.position.x < screenWidth / 2 {
            hero.hero.position.x = screenWidth / 2
        }
        */
    }
    
    func addRandomEnemy(){
        let chanceForSmallEnemy = 5
        var enemyPositionX:CGFloat = -400
        let randomPosition = CGPoint(x:enemyPositionX, y:randomBetweenNumbers(0, secondNum: background.size.height))
        
        //if Int(arc4random_uniform(11)) < 4 {
        //    addEnemyGroup(10, size: 1, position: randomPosition.y)
        //}
        //else {
        let resourcePath = NSBundle.mainBundle().pathForResource("Enemy", ofType: "sks")
        let enemyReferenceNode = EnemyReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
        let enemy = enemyReferenceNode.enemySprite
        let enemySizeMax:CGFloat = 4, enemySizeMin:CGFloat = 1
    
        // random position
        enemy.position = randomPosition
        
        // random speed
        let randomSpeed = randomBetweenNumbers(1, secondNum: 3)
        
        /*
        if enemy.position.y > 5500 { // top position
            enemySizeMin = 0.3
            enemySizeMax = 1.5
            chanceForSmallEnemy = 8
            randomSpeed = randomBetweenNumbers(1, secondNum: 5)
        }
        else if enemy.position.y > 4600 {
            enemySizeMin = 1
            enemySizeMax = 3
            chanceForSmallEnemy = 4
        }
        else if enemy.position.y > 3200 {
            enemySizeMin = 3
            enemySizeMax = 5
            chanceForSmallEnemy = 1
        }
        else if enemy.position.y > 860 {
            enemySizeMin = 5
            enemySizeMax = 7
            chanceForSmallEnemy = 0
        }
        else { // below 860
            enemySizeMin = 7
            enemySizeMax = 10
            chanceForSmallEnemy = 0
        }
        */
        enemy.movementSpeed = randomSpeed
        
        if arc4random_uniform(11) > 5 { // random 50%
            enemy.position.x = self.frame.width + 400
            enemy.direction = .Left
            enemy.movementSpeed = -enemy.movementSpeed
            enemy.xScale = -enemy.xScale
        }
        
        var randomSize = randomBetweenNumbers(enemySizeMin, secondNum: enemySizeMax)
        //if Int(arc4random_uniform(11)) < chanceForSmallEnemy {
        //    randomSize = randomBetweenNumbers(0.5, secondNum: hero.hero.sizeValue)
        //}
        
        enemy.setScale(randomSize)
        enemy.sizeValue = randomSize
        
        addChild(enemyReferenceNode)
        enemies.insert(enemy)
        //}
    }
    /*
    func addEnemyGroup(amount:Int, size:CGFloat, position:CGFloat){
        for i in 1...amount {
            let enemyPositionX:CGFloat = self.frame.width + 100
            let randomPosition = CGPoint(x:enemyPositionX, y:randomBetweenNumbers(position - 5, secondNum: position + 5))
            
            let resourcePath = NSBundle.mainBundle().pathForResource("Enemy", ofType: "sks")
            let enemyReferenceNode = EnemyReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
            let enemy = enemyReferenceNode.enemySprite
            
            // random position
            enemy.position = randomPosition
            
            // random speed
            var randomSpeed = randomBetweenNumbers(1, secondNum: 2)
            
            enemy.movementSpeed = randomSpeed
            enemy.direction = .Left
            enemy.movementSpeed = -enemy.movementSpeed
            
            var randomSize = randomBetweenNumbers(size - 0.5, secondNum: size + 0.5)
            
            enemy.setScale(randomSize)
            enemy.sizeValue = randomSize
            
            addChild(enemyReferenceNode)
            enemies.insert(enemy)
        }
    }
    */
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
        
        func heroEnemyContact(hero:Hero, enemy:Enemy){
            //print("enemy size: \(enemy.sizeValue)")
            //print("hero size: \(hero.sizeValue)")
            
            if hero.sizeValue > enemy.sizeValue {
                enemies.remove(enemy)
                enemy.removeFromParent()
                hero.sizeValue += 0.05
                hero.runAction(SKAction.scaleTo(hero.sizeValue, duration: 0.2))
            }
            else{
                
                // use SKAction or separate function
                print("DEAD")
                // restart game
                let skView = self.view as SKView!
                /* Load Game scene */
                let scene = GameScene(fileNamed:"GameScene") as GameScene!
                /* Ensure correct aspect mode */
                scene.scaleMode = .AspectFill
                /* Restart game scene */
                skView.presentScene(scene)
            }
 
        }
        
        func heroWallContact(hero:Hero, wall:SKNode){
            print("hero contacted wall")
            
            impulseX = -impulseX
            impulseXContinuous = -impulseXContinuous
        }
        
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if (nodeA.name == "hero" && nodeB.name == "enemy"){
            heroEnemyContact(nodeA as! Hero, enemy: nodeB as! Enemy)
        }
        else if (nodeA.name == "enemy" && nodeB.name == "hero") {
            heroEnemyContact(nodeB as! Hero, enemy: nodeA as! Enemy)
        }
    }
}
