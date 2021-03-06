//
//  SEGravitationalSimulationNode.swift
//  Test
//
//  Created by Travis Fischer on 6/23/15.
//  Copyright (c) 2015 Sesh. All rights reserved.
//

import SpriteKit

class SEGravitationalSimulationNode: SKEffectNode {
    
    static let s_shader = SKShader(fileNamed: "GravitationalSimulation")
    
    let kGravitationalBodyMaxForce: CGFloat     = 5000.0
    let kGravitationalBodyMaxVelocity: CGFloat  = 200.0
    
    var radius: CGFloat
    var numNodes: Int

    var _forces: [ CGVector ] = [ ]
    var _simulation: SKNode!
    var _joints: [ SKPhysicsJointLimit ] = [ ]
    var _jointDistances: [ CGFloat ] = [ ]
    var _compression: CGFloat = 0.0
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    init(numNodes: Int, radius: CGFloat) {
        self.numNodes = numNodes
        self.radius = radius
        
//        super.init(texture: SKTexture(imageNamed: "dummy"), color: UIColor.clearColor(), size: CGSizeMake(radius * 2, radius * 2))
        super.init()
        self.shader = SEGravitationalSimulationNode.s_shader
        
        for i in 0 ..< numNodes {
            let r = (i == 0 ? radius * 10 : radius / 8.0 + CGFloat.random() * radius / 2.0)
            let node = SEGravitationalBodyNode(radius: r)
            
            if (i == 0) {
                node.position = CGPoint()
                node.size = CGSize(width: radius * 4, height: radius * 4)
                node.isHidden = true
                
                node.physicsBody = SKPhysicsBody(circleOfRadius: r)
                node.physicsBody?.isDynamic = false
            } else {
                node.position = CGPoint(x: CGFloat.random(min: -1.0, max: 1.0), y: CGFloat.random(min: -1.0, max: 1.0)) * radius
                node.size = CGSize(width: r * 2, height: r * 2)
                //node.hidden = true
                
                node.physicsBody = SKPhysicsBody(circleOfRadius: r)
            }
            
            node.physicsBody?.affectedByGravity = false
            node.physicsBody?.collisionBitMask = 0
            node.physicsBody?.mass = r
            
            self._forces.append(CGVector())
            self.addChild(node)
        }
        
//        self._simulation = SKNode()
//        //self._simulation.setScale(0.5)
//        
//        for n in self.children {
//            let node1 = n as! SEGravitationalBodyNode
//            let node2 = SEGravitationalBodyNode(radius: node1.radius)
//            
//            node2.position = node1.position
//            node2.size = node1.size
//            
//            self._simulation.addChild(node2)
//        }
//        
//        self._simulation.children[0].hidden = true
    }
    
    func update (_ currentTime: CFTimeInterval) {
        /*let minForce = CGPoint(x: -kGravitationalBodyMaxForce, y: -kGravitationalBodyMaxForce)
        let maxForce = CGPoint(x: kGravitationalBodyMaxForce, y: kGravitationalBodyMaxForce)
        
        let minVelocity = CGVector(dx: -kGravitationalBodyMaxVelocity, dy: -kGravitationalBodyMaxVelocity)
        let maxVelocity = CGVector(dx: kGravitationalBodyMaxVelocity, dy: kGravitationalBodyMaxVelocity)*/
        
        if (self._joints.count == 0) {
            var bodyA: SKPhysicsBody? = nil
            var anchorA: CGPoint? = nil
            
            for i in 0 ..< self.numNodes {
                let node: SEGravitationalBodyNode = self.children[i] as! SEGravitationalBodyNode
                
                if (i == 0) {
                    bodyA = node.physicsBody
                    anchorA = self.scene?.convert(CGPoint.zero, from: self.children[0])
                } else {
                    let anchorB = self.scene!.convert(CGPoint.zero, from: node)
                    let joint = SKPhysicsJointLimit.joint(withBodyA: bodyA!, bodyB: node.physicsBody!, anchorA: anchorA!, anchorB: anchorB)
                    let maxLength: CGFloat = self.radius / 10 + CGFloat.random() * (self.radius + CGFloat.random(min: -1.0, max: 1.0) * (self.radius / 10.0))
                    joint.maxLength = maxLength
                    
                    self._joints.append(joint)
                    self._jointDistances.append(maxLength)
                    
                    self.scene?.physicsWorld.add(joint)
                }
            }
        }
        
        for i in 0 ..< self.numNodes {
            self._forces[i] = CGVector()
        }
        
        let forceMultiplier: CGFloat = 32.0 * (1.0 - self.compression);
        
        // calculate n-body forces
        for i in 0 ..< self.numNodes {
            let node1: SEGravitationalBodyNode = self.children[i] as! SEGravitationalBodyNode
            let radius1: CGFloat = node1.radius
            var force = self._forces[i]
            
            for j in i + 1 ..< self.numNodes {
                let node2: SEGravitationalBodyNode = self.children[j] as! SEGravitationalBodyNode
                
                let delta: CGVector = CGVector(point: node1.position - node2.position)
                let sqDist: CGFloat = delta.lengthSquared()
                
                if sqDist > 0.1 {
                    let invSqDist: CGFloat = 1.0 / sqDist
                    let radius2: CGFloat = node2.radius
                    
                    force += delta * (-radius2 * radius2 * forceMultiplier * invSqDist)
                    
                    self._forces[j] += delta * (radius1 * forceMultiplier * invSqDist)
                }
            }
            
            self._forces[i] = force
        }
        
        // apply forces to bodies
        for i in 1 ..< self.numNodes {
            let node: SEGravitationalBodyNode = self.children[i] as! SEGravitationalBodyNode
            var force = self._forces[i]
            
            //print("force: \(NSStringFromCGVector(force)); velocity: \(NSStringFromCGVector(node.physicsBody!.velocity))")
            
            force = CGVector(
                dx: force.dx.clamped(-kGravitationalBodyMaxForce, kGravitationalBodyMaxForce),
                dy: force.dy.clamped(-kGravitationalBodyMaxForce, kGravitationalBodyMaxForce)
            )
            
            node.physicsBody?.applyForce(self._forces[i])
            
            let v = node.physicsBody!.velocity
            node.physicsBody!.velocity = CGVector(
                dx: v.dx.clamped(-kGravitationalBodyMaxVelocity, kGravitationalBodyMaxVelocity),
                dy: v.dy.clamped(-kGravitationalBodyMaxVelocity, kGravitationalBodyMaxVelocity)
            )
        }
        
//        self._simulation.position = CGPointZero
//        
//        for var i = 0; i < self.numNodes; ++i {
//            let node1 = self.children[i] as! SEGravitationalBodyNode
//            let node2 = self._simulation.children[i] as! SEGravitationalBodyNode
//            
//            node2.position = node1.position
//        }
//        
////        print("frame: \(NSStringFromCGSize(self._simulation.calculateAccumulatedFrame().size)); \(NSStringFromCGSize(self.size))")
//        
//        let yRatio: CGFloat = 1.0 * self._simulation.xScale
//        let xRatio: CGFloat = 1.0 * self._simulation.yScale
//        
//        // render hidden children to offscreen texture
//        self.texture = self.scene!.view!.textureFromNode(self._simulation,
//            crop: CGRect(origin: CGPoint(x: -self.size.width * xRatio / 2.0, y: -self.size.height * yRatio / 2.0),
//            size: CGSize(width: self.size.width * xRatio, height: self.size.height * yRatio)))
    }
    
    var compression: CGFloat {
        get {
            return self._compression;
        }

        set {
            // change limit joint distances gradually
            self.run(SKAction.customAction(withDuration: 1.0, actionBlock: { (node, t) -> Void in
                for i in 0 ..< self.numNodes - 1 {
                    let joint = self._joints[i]
                    let maxLength = self._jointDistances[i]
                    let newMaxLength = (self.radius / 5.0) * newValue + maxLength * (1.0 - newValue)
                    
                    self.scene?.physicsWorld.remove(joint)
                    joint.maxLength = t * newMaxLength + (1 - t) * maxLength
                    self.scene?.physicsWorld.add(joint)
                }
            }))
        }
    }
}
