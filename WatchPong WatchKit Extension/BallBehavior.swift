//
//  BallBehavior.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import WatchScene2D

class BallBehavior : W2DComponent, W2DBehavior
{
    var     fBallDirection : CGPoint = CGPointMake(0, 0)
    var     fBallSpeed : CGFloat = 0;
    
    override init()
    {
        super.init()
        
        // random angle between -45 and 45
        let rInt = rand()
        let r = Float(Double(rInt) / Double(RAND_MAX))
        let minV : Float = -45.0
        let maxV : Float = 45.0
        let a = (r * (maxV - minV)) + minV
        
        let angle = Float(a) * Float(M_PI) / 180
        
        let x = CGFloat(-cosf(angle))
        let y = CGFloat(-sinf(angle))
        
        // normalization is in theory already normalized...
        fBallDirection = CGPoint(x:x, y:y).normalizedVector()
        
        fBallSpeed = 60.0
    }
    
    func execute(dT:NSTimeInterval, director:W2DDirector!)
    {
        let dV = fBallSpeed * CGFloat(dT)
        
        let sprite : W2DSprite? = component()
        
        guard let ballSprite = sprite
        else
        {
            return;
        }
        
        // try to collide with any collider in the scene
        let collisions = Collider.collideInScene(director.currentScene!, ball: sprite, direction:fBallDirection, instantaneousSpeed:dV)
        if !collisions.isEmpty
        {
            var closestCollision : Collision?
            var minT = CGFloat.max
            
            for c in collisions
            {
                if (c.t < minT)
                {
                    minT = c.t
                    closestCollision = c
                }
            }
            
            fBallDirection = closestCollision!.direction
            fBallSpeed *= closestCollision!.bounceSpeedFactor
            if fBallSpeed > 120
            {
                fBallSpeed = 120
            }
        }
        else
        {
            // move the ball linearly
            let v = fBallDirection.mul(dV);
            
            let newBallPos = ballSprite.position.add(v)
            ballSprite.position = newBallPos
        }
    }
}

