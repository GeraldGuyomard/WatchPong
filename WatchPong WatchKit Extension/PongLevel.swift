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
    var     fBallSprite : W2DSprite?
    var     fPadSprite : W2DSprite?
    
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
    
    func createScene(director:W2DDirector) -> W2DScene
    {
        let context = director.context
        
        let scene = W2DScene()
        scene.addComponent(self)
        
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
        
        fBallSprite = W2DSprite(named: "ball.png", inContext:context)
        scene.addChild(fBallSprite)
        
        let ballBeh = BallBehavior()
        fBallSprite?.addComponent(ballBeh)
        director.addBehavior(ballBeh)
        
        fPadSprite = W2DSprite(named:"pad.png", inContext:context)
        scene.addChild(fPadSprite)
        
        fPadSprite!.position = CGPointMake(CGFloat(context.width) - fPadSprite!.size.width, 0)
        
        let padBeh = Collider()
        padBeh.bounceSpeedFactor = 1.3
        padBeh.collisionCallback = {
        (collision:Collision) -> Collision? in
        {
            WKInterfaceDevice.currentDevice().playHaptic(.Retry)
            return collision
        }()}
        
        fPadSprite!.addComponent(padBeh)
        
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
        
        let ballSize = fBallSprite!.size
        let ballPos = CGPointMake(contextWidth - (2 * ballSize.width), (contextHeight - ballSize.height) / 2)
        fBallSprite!.position = ballPos
        
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
        let availableHeight = CGFloat(context.height) - fPadSprite!.size.height
        
        var pos = fPadSprite!.position
        pos.y = CGFloat(value) * availableHeight
        fPadSprite!.position = pos
    }

}
