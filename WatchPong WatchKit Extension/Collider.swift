//
//  Collider.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import Foundation
import WatchScene2D

public class Collider : W2DComponent
{
    static public func collideInScene(scene:W2DScene!, ball:W2DNode!, direction:CGPoint, instantaneousSpeed:CGFloat) -> [Collision]
    {
        var collisions = [Collision]()
        _collideRecursive(scene, considerThisNode: false, ball:ball, direction:direction, instantaneousSpeed:instantaneousSpeed, collisions:&collisions)
        return collisions
    }
    
    static private func _collideRecursive(node:W2DNode!, considerThisNode:Bool, ball:W2DNode!, direction:CGPoint, instantaneousSpeed:CGFloat, inout collisions:[Collision])
    {
        if considerThisNode
        {
            let collider : Collider? = node.component()
            if let c = collider
            {
                if let collision = c.collide(ball, direction: direction, instantaneousSpeed:instantaneousSpeed)
                {
                    collisions.append(collision)
                }
            }
        }
        
        if let children = node.children
        {
            for child in children
            {
                _collideRecursive(child, considerThisNode: true, ball: ball, direction: direction, instantaneousSpeed: instantaneousSpeed, collisions:&collisions)
            }
        }
    }
    
    public var bounceSpeedFactor : CGFloat = 1.0
    
    public var collisionCallback : ((collision:Collision) -> Collision?)?
    
    public func collide(otherNode:W2DNode!, direction:CGPoint, instantaneousSpeed:CGFloat) -> Collision?
    {
        let m : W2DNode? = component()
        guard let myNode = m
        else
        {
            return nil
        }
        
        // first easy rejections with AABBs
        let myBox = myNode.globalBox
        let otherBox = otherNode.globalBox
        
        var otherMovedBox = otherBox
        otherMovedBox.origin = otherMovedBox.origin.add(direction.mul(instantaneousSpeed))
        
        let otherMovingBox = CGRectUnion(otherBox, otherMovedBox)
        
        if (!myBox.intersects(otherMovingBox))
        {
            return nil
        }
        
        // ray box intersection is happening now
        let radius = otherBox.size.width
        let halfRadius = radius / 2.0
        let pos = CGPointMake(otherBox.origin.x + halfRadius, otherBox.origin.y + halfRadius)
        
        var collision: Collision? = nil
        
        //let overhead = halfRadius
        let overhead : CGFloat = 0
        //let overhead : CGFloat = radius / 4
        
        let maxValidT = CGFloat.max //halfRadius
        
        if direction.y != 0
        {
            let invVY = 1.0 / direction.y
            
            // try bottom horizontal edge
            if (direction.y > 0)
            {
                let t = (myBox.origin.y - pos.y) * invVY
                if (t >= 0) && (t <= maxValidT)
                {
                    if (collision == nil) || (t < collision!.t)
                    {
                        let x = (t * direction.x) + pos.x
                        if (x >= myBox.origin.x - overhead) && (x <= myBox.origin.x + myBox.size.width + overhead)
                        {
                            let newDirection = CGPointMake(direction.x, -direction.y)
                            collision = Collision(node:myNode, direction:newDirection, bounceSpeedFactor:bounceSpeedFactor, t:t, edge:.bottom)
                        }
                    }
                }
            }
            else
            {
                // try top horizontal edge
                let t = ((myBox.origin.y + myBox.size.height) - pos.y) * invVY
                if (t >= 0) && (t <= maxValidT)
                {
                    if (collision == nil) || (t < collision!.t)
                    {
                        let x = (t * direction.x) + pos.x
                        if (x >= myBox.origin.x - overhead) && (x <= myBox.origin.x + myBox.size.width + overhead)
                        {
                            let newDirection = CGPointMake(direction.x, -direction.y)
                            collision = Collision(node:myNode, direction:newDirection, bounceSpeedFactor:bounceSpeedFactor, t:t, edge:.top)
                        }
                    }
                }
            }
        }
        
        if direction.x != 0
        {
            let invVX = 1.0 / direction.x
            
            if direction.x > 0
            {
                // try left vertical edge
                let t = (myBox.origin.x - pos.x) * invVX
                if (t >= 0) && (t <= maxValidT)
                {
                    if (collision == nil) || (t < collision!.t)
                    {
                        let y = (t * direction.y) + pos.y
                        if (y >= myBox.origin.y - overhead) && (y <= myBox.origin.y + myBox.size.height + overhead)
                        {
                            let newDirection = CGPointMake(-direction.x, direction.y)
                            collision = Collision(node:myNode, direction:newDirection, bounceSpeedFactor:bounceSpeedFactor, t:t, edge:.left)
                        }
                    }
                }
            }
            else
            {
                // try right vertical edge
                let t = ((myBox.origin.x + myBox.size.width) - pos.x) * invVX
                if (t >= 0) && (t <= maxValidT)
                {
                    if (collision == nil) || (t < collision!.t)
                    {
                        let y = (t * direction.y) + pos.y
                        if (y >= myBox.origin.y - overhead) && (y <= myBox.origin.y + myBox.size.height + overhead)
                        {
                            let newDirection = CGPointMake(-direction.x, direction.y)
                            collision = Collision(node:myNode, direction:newDirection, bounceSpeedFactor:bounceSpeedFactor, t:t, edge:.right)
                        }
                    }
                }
            }
        }
        
        if let c = collision
        {
            if let cb = self.collisionCallback
            {
                collision = cb(collision: c)
            }
        }
        
        return collision
    }
    
}
