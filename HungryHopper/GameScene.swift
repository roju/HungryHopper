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
    let enemyDelaySeconds:CFTimeInterval = 0.5
    var enemies = Set<Enemy>()
    var background:SKSpriteNode!
    //let screenHeight:CGFloat = 480
    //let screenWidth:CGFloat = 320
    //var impulseX:CGFloat = 0.0
    var cam:SKCameraNode!
    
    var chanceForSmallEnemy = 5
    
    override func didMoveToView(view: SKView) {
        background = childNodeWithName("background") as! SKSpriteNode
        
        let resourcePath = NSBundle.mainBundle().pathForResource("Hero", ofType: "sks")
        hero = MSReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
        
        hero.hero.position = CGPoint(x: self.frame.width/2 - 50, y:self.frame.height/2)
        addChild(hero)
        
        physicsWorld.contactDelegate = self
        
        /* Camera */
        cam = SKCameraNode() //initialize and assign an instance of SKCameraNode to the cam variable.
        cam.scaleAsPoint = CGPoint(x: 1.8, y: 1.8) //the scale sets the zoom level of the camera on the given position
        
        self.camera = cam //set the scene's camera to reference cam
        self.addChild(cam) //make the cam a childElement of the scene itself.
        
        //position the camera on the gamescene.
        cam.position = hero.hero.position //CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        
        self.physicsWorld.gravity = CGVectorMake(0.0, -3.0);
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = true
        
        /*
        impulseX = CGRectGetMidX(self.frame)
        
        let touch = touches.first
        let position = touch!.locationInView(self.view)
        let touchX = position.x
        print("raw x: \(touchX)")
        
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
        let middleOfView = (self.view!.frame.width) / 2
        if touchX > middleOfView + 100 {
            print("touching right side")
            impulseX = -0.05
        }
        else if touchX < middleOfView - 80 {
            print("touching left side")
            impulseX = 0.05
        }
        else {
            print("touching middle")
            impulseX = 0
        }
         */
        
        //print("xMOD: \(impulseX)")
        
        //hero.hero.physicsBody?.velocity = CGVectorMake(0, 0)
        hero.hero.physicsBody?.applyImpulse(CGVectorMake(0, 0.8))
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

    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isTouching = false
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if isTouching {
            //print("xMOD: \(impulseX)")
            hero.hero.physicsBody!.applyImpulse(CGVectorMake(0, 0.3))
        }
        
        //cam.position = hero.hero.position
        
        let moveCamToPlayer =  SKAction.moveTo(hero.hero.position, duration: 0.1)
        cam.runAction(moveCamToPlayer)
        
        if enemyTimer >= enemyDelaySeconds {
            addEnemy()
            enemyTimer = 0
        }
        
        moveEnemies()
        
        for enemy in enemies {
            if (enemy.direction == .Right && enemy.position.x > self.frame.width + 200) ||
                (enemy.direction == .Left && enemy.position.x < -200) {
                
                //print("removed enemy at: \(enemy.position.x)")
                enemies.remove(enemy)
                
                enemy.removeFromParent()
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
    
    func addEnemy(){
        let resourcePath = NSBundle.mainBundle().pathForResource("Enemy", ofType: "sks")
        let enemyReferenceNode = EnemyReferenceNode(URL: NSURL (fileURLWithPath: resourcePath!))
        let enemy = enemyReferenceNode.enemySprite
        
        let randomSpeed = randomBetweenNumbers(0.7, secondNum: 4)
        enemy.movementSpeed = randomSpeed
        
        var enemyPositionX:CGFloat// = -100
        
        //if arc4random_uniform(11) > 5 { // random 50%
            enemyPositionX = self.frame.width + 100
            enemyReferenceNode.enemySprite.direction = .Left
            enemy.movementSpeed = -enemy.movementSpeed
        //}
        
        var randomSize = randomBetweenNumbers(1, secondNum: hero.hero.sizeValue + 3)
        if Int(arc4random_uniform(11)) > chanceForSmallEnemy {
            randomSize = randomBetweenNumbers(0.5, secondNum: hero.hero.sizeValue)
        }
        
        
        enemy.setScale(randomSize)
        enemy.sizeValue = randomSize
        
        let bgHeight = background.size.height
        enemy.position = CGPoint(x:enemyPositionX, y:randomBetweenNumbers(0, secondNum: bgHeight))
        
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
