//
//  MovingObject.swift
//  WatchPong
//
//  Created by Gérald Guyomard on 5/12/16.
//  Copyright © 2016 Gérald Guyomard. All rights reserved.
//

import WatchKit
import WatchScene2D

public protocol MovingObject : class
{
    var direction : CGPoint { get set }
    var speed : CGFloat { get set }
    
    func resetToInitialState()
}