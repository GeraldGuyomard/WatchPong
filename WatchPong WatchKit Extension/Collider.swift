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
    static public func collideInScene(scene:W2DScene!, ball:W2DNode!, direction:CGPoint) -> Collision?
    {
        return _collideRecursive(scene, considerThisNode: false, ball:ball, direction:direction)
    }
    
    static private func _collideRecursive(node:W2DNode!, considerThisNode:Bool, ball:W2DNode!, direction:CGPoint) -> Collision?
    {
        if considerThisNode
        {
            let collider : Collider? = node.component()
            if let c = collider
            {
                let collision = c.collide(ball, direction: direction)
                if collision != nil
                {
                    return collision
                }
            }
        }
        
        if let children = node.children
        {
            for child in children
            {
                let c = _collideRecursive(child, considerThisNode: true, ball: ball, direction: direction)
                if c != nil
                {
                    return c
                }
            }
        }
        
        return nil
    }
    
    public func collide(otherNode:W2DNode!, direction:CGPoint) -> Collision?
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
        otherMovedBox.origin = otherMovedBox.origin.add(direction)
        
        let otherMovingBox = CGRectUnion(otherBox, otherMovedBox)
        
        if (!myBox.intersects(otherMovingBox))
        {
            return nil
        }
        
        // ray box intersection is happening now
        let halfRadius = otherBox.size.width / 2.0
        let pos = CGPointMake(otherBox.origin.x + halfRadius, otherBox.origin.y + halfRadius)
        let normalizedDir = direction.normalizedVector()
        let bounceBackdir = normalizedDir.opposite()
        
        var collision: Collision? = nil
        
        if normalizedDir.y != 0
        {
            let invVY = 1.0 / normalizedDir.y
            
            // try bottom horizontal edge
            var t = (myBox.origin.y - pos.y) * invVY
            if (t >= 0) && (t <= halfRadius)
            {
                if (collision == nil) || (t < collision!.t)
                {
                    let x = (t * normalizedDir.x) + pos.x
                    if (x >= myBox.origin.x - halfRadius) && (x <= myBox.origin.x + myBox.size.width + halfRadius)
                    {
                        let newPos = pos.add(bounceBackdir.mul(halfRadius))
                        
                        collision = Collision(node:myNode, position:newPos, direction:CGPointMake(direction.x, -direction.y), t:t, edge:.bottom)
                    }
                }
            }
            
            // try top horizontal edge
            t = ((myBox.origin.y + myBox.size.height) - pos.y) * invVY
            if (t >= 0) && (t <= halfRadius)
            {
                if (collision == nil) || (t < collision!.t)
                {
                    let x = (t * normalizedDir.x) + pos.x
                    if (x >= myBox.origin.x - halfRadius) && (x <= myBox.origin.x + myBox.size.width + halfRadius)
                    {
                        let newPos = pos.add(bounceBackdir.mul(halfRadius))
                        
                        collision = Collision(node:myNode, position:newPos, direction:CGPointMake(direction.x, -direction.y), t:t, edge:.top)
                    }
                }
            }
        }
        
        if normalizedDir.x != 0
        {
            let invVX = 1.0 / normalizedDir.x
            
            // try left vertical edge
            var t = (myBox.origin.x - pos.x) * invVX
            if (t >= 0) && (t <= halfRadius)
            {
                if (collision == nil) || (t < collision!.t)
                {
                    let y = (t * normalizedDir.y) + pos.y
                    if (y >= myBox.origin.y - halfRadius) && (y <= myBox.origin.y + myBox.size.height + halfRadius)
                    {
                        let newPos = pos.add(bounceBackdir.mul(halfRadius))
                        
                        collision = Collision(node:myNode, position:newPos, direction:CGPointMake(-direction.x, direction.y), t:t, edge:.left)
                    }
                }
            }
            
            // try right vertical edge
            t = ((myBox.origin.x + myBox.size.width) - pos.x) * invVX
            if (t >= 0) && (t <= halfRadius)
            {
                if (collision == nil) || (t < collision!.t)
                {
                    let y = (t * normalizedDir.y) + pos.y
                    if (y >= myBox.origin.y - halfRadius) && (y <= myBox.origin.y + myBox.size.height + halfRadius)
                    {
                        let newPos = pos.add(bounceBackdir.mul(halfRadius))
                        
                        collision = Collision(node:myNode, position:newPos, direction:CGPointMake(-direction.x, direction.y), t:t, edge:.right)
                    }
                }
            }
        }
        
        return collision
    }
}
