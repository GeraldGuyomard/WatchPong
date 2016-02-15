//
//  PongLevel.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import WatchScene2D

class PongLevel : W2DComponent
{
    var     fBalls =  [W2DNode]()
    var     fPads = [W2DNode]()
    
    var     fMustStartGame = true;
    var     fLost = false;
    
    func willActivate(director:W2DDirector!)
    {
        if (fMustStartGame)
        {
            fMustStartGame = false
            startGame(director)
        }
    }
    
    func createBrick(scene:W2DScene, image:W2DImage) -> W2DNode
    {
        let brick = W2DSprite(image:image)
        scene.addChild(brick)
        
        let collider = Collider()
        collider.collisionCallback = {
            [](collision:Collision) -> Collision? in
            {
                collision.node.removeFromParent()
                
                return collision
            }()}
        
        brick.addComponent(collider)
        
        return brick
    }
    
    func createBorders(scene:W2DScene, inContext context:W2DContext)
    {
        let screenSize = CGSizeMake(CGFloat(context.width), CGFloat(context.height))
        let color = W2DColor4f(red: 1.0, green: 1.0, blue: 1.0)
        
        let topBorder = W2DColoredNode(color: color)
        topBorder.size = CGSizeMake(screenSize.width, 4.0);
        topBorder.position = CGPointMake(0, 0)
        topBorder.addComponent(Collider())
        scene.addChild(topBorder)
        
        let bottomBorder = W2DColoredNode(color: color)
        bottomBorder.size = CGSizeMake(screenSize.width, 4.0);
        bottomBorder.position = CGPointMake(0, screenSize.height - bottomBorder.size.height)
        bottomBorder.addComponent(Collider())
        scene.addChild(bottomBorder)
        
        let leftBorder = W2DColoredNode(color: color)
        leftBorder.size = CGSizeMake(4, screenSize.height);
        leftBorder.position = CGPointMake(0, 0)
        leftBorder.addComponent(Collider())
        scene.addChild(leftBorder)
    }
    
    func createBricks(scene:W2DScene, inContext context:W2DContext)
    {
        var pt = CGPointMake(16, 0);
        
        let brickImage = context.image(named:"brick-red.png")
        let brickSize = brickImage!.size
        
        for _ in 1...6
        {
            let brick = createBrick(scene, image:brickImage!)
            brick.position = pt
            
            pt.y += brickSize.height * 1.05
        }
        
        pt = CGPointMake(16 + 2 * brickSize.width, brickSize.height * 0.5)
        for _ in 1...4
        {
            let brick = createBrick(scene, image:brickImage!)
            brick.position = pt
            
            pt.y += brickSize.height * 1.1
        }
        
        pt = CGPointMake(16 + 4 * brickSize.width, brickSize.height * 0.25)
        for _ in 1...2
        {
            let brick = createBrick(scene, image:brickImage!)
            brick.position = pt
            
            pt.y += brickSize.height * 2
        }
    }
    
    func createBall(scene:W2DScene, inDirector director:W2DDirector) -> W2DNode
    {
        let sprite = W2DSprite(named: "ball.png", inContext:director.context)
        scene.addChild(sprite)
        
        let ballBeh = BallBehavior()
        sprite.addComponent(ballBeh)
        director.addBehavior(ballBeh)
 
        return sprite
    }
    
    func createPad(scene:W2DScene, inContext context:W2DContext) -> W2DNode
    {
        let sprite = W2DSprite(named:"pad.png", inContext:context)
        scene.addChild(sprite)
        
        sprite.position = CGPointMake(CGFloat(context.width) - sprite.size.width, 0)
        let padBeh = Collider()
        padBeh.bounceSpeedFactor = 1.3
        padBeh.collisionCallback = {
            (collision:Collision) -> Collision? in
            {
                WKInterfaceDevice.currentDevice().playHaptic(.Retry)
                return collision
            }()}
        
        sprite.addComponent(padBeh)
        
        return sprite
    }
    
    func createScene(director:W2DDirector) -> W2DScene
    {
        let scene = W2DScene()
        scene.addComponent(self)
        
        let context = director.context
        
        createBorders(scene, inContext:context)
        createBricks(scene, inContext:context)
        
        let ball = createBall(scene, inDirector:director)
        fBalls.append(ball)
        
        let pad = createPad(scene, inContext:context)
        fPads.append(pad)
        
        return scene
    }
    
    func startGame(director:W2DDirector!)
    {
        let context = director.context
        
        let contextWidth = CGFloat(context.width)
        let contextHeight = CGFloat(context.height)
        
        let normalizedPadY = Float(0.5)
        director.setDigitalCrownValue(normalizedPadY)
        self.setPadPosition(normalizedPadY, director:director)
        
        for ball in fBalls
        {
            let ballSize = ball.size
            let ballPos = CGPointMake(contextWidth - (2 * ballSize.width), (contextHeight - ballSize.height) / 2)
            ball.position = ballPos
        }

        fLost = false
        director.currentScene!.backgroundColor = W2DColor4f()
    }

    func onLost(director:W2DDirector!)
    {
        fLost = true
        director.currentScene!.backgroundColor = W2DColor4f(red:1, green:0, blue:0)
        
        WKInterfaceDevice.currentDevice().playHaptic(.Failure)
        
        director.stop()
    }
    
    func setPadPosition(value:Float, director:W2DDirector!)
    {
        let context = director.context
        
        for pad in fPads
        {
            let availableHeight = CGFloat(context.height) - pad.size.height
            
            var pos = pad.position
            pos.y = CGFloat(value) * availableHeight
            pad.position = pos
        }
    }

}
