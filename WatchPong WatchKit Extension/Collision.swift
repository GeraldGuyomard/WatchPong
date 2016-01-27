//
//  Collision.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 1/17/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import Foundation
import WatchScene2D

public struct Collision
{
    public var node : W2DNode!
    public var position : CGPoint
    public var direction : CGPoint
    public var bounceSpeedFactor: CGFloat
    public var t : CGFloat
    
    public enum Edge
    {
        case left
        case top
        case right
        case bottom
    }
    
    public var edge : Edge
}