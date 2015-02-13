//
//  GameScene.swift
//  Hasami
//
//  Created by yasu on 2015/02/07.
//  Copyright (c) 2015年 yasu. All rights reserved.
//

import SpriteKit

let SCALE: CGFloat = 0.7
let align: CGFloat = 62

protocol PieceTouchDelegate {
    func touchedPiece(piece:PieceNode)
}

class PieceNode: SKSpriteNode {
    enum Type: String {
        case ho = "koma_ho.png"
        case to = "koma_to_r.png"
        case hoh = "koma_ho_hover.png"
        case toh = "koma_to_hover_r.png"
        case masu = "masu_hover.png"
    }
    var point : Point?
    var piecetype : Type? {
        didSet {
            self.texture = SKTexture(imageNamed: piecetype!.rawValue)
        }
    }
    var delegate : PieceTouchDelegate?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize)
    {
        super.init(texture: texture, color: color, size: size)
    }
    
    convenience init(type: Type)
    {
        let color = UIColor()
        let texture = SKTexture(imageNamed: type.rawValue)
        let size = CGSizeMake(texture.size().width, texture.size().height)
        self.init(texture: texture, color: color, size: size)
        self.piecetype = type
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func hover() {
        switch piecetype! {
        case .ho:
            piecetype = .hoh
        case .to:
            piecetype = .toh
        case .masu:
            self.hidden = false
        default:
            break
        }
    }
    
    func unhover() {
        switch piecetype! {
        case .hoh:
            piecetype = .ho
        case .toh:
            piecetype = .to
        case .masu:
            self.hidden = true
        default:
            break
        }
    }
    
    var _position : CGPoint?
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            _position = self.position
        }
        delegate?.touchedPiece(self)
    }
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if self.piecetype == .masu {
            return
        }
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self.parent)
            self.position = location
        }
    }
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            self.position = _position!
            if touch.tapCount == 0 {
                return
            }
        }
    }
}

class GameScene: SKScene {
    var shougiContnroller: ShougiController
    var masuNodeArray: [[PieceNode?]]
    var boardNode: SKSpriteNode
    var pieceNodeArray: [PieceNode?]
    
    required init?(coder aDecoder: NSCoder) {
        shougiContnroller = ShougiController()
        boardNode = SKSpriteNode(imageNamed: "ban.png")
        boardNode.xScale = SCALE
        boardNode.yScale = SCALE
        masuNodeArray = Array(count: 9, repeatedValue: Array(count: 9, repeatedValue: nil))
        pieceNodeArray = Array()
        super.init(coder: aDecoder)
    }
    override func didMoveToView(view: SKView) {
        boardNode.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        self.addChild(boardNode)

        for i in 0...8 {
            for j in 0...8 {
                var newPiece : PieceNode = PieceNode(type: .masu)
                newPiece.position = CGPoint(x: CGFloat(j-4)*align, y: CGFloat(4-i)*align)
                newPiece.userInteractionEnabled = true
                newPiece.hidden = true
                masuNodeArray[i][j] = newPiece
                boardNode.addChild(newPiece)
            }
        }
        for i in 0...8 {
            var newPiece : PieceNode = PieceNode(type: .ho)
            newPiece.position = CGPoint(x: CGFloat(i-4)*align, y: CGFloat(-4)*align)
            newPiece.userInteractionEnabled = true
            newPiece.delegate = self
            newPiece.point = Point(y: 8, x: i)
            pieceNodeArray.append(newPiece)
            boardNode.addChild(newPiece)
        }
        for i in 0...8 {
            var newPiece : PieceNode = PieceNode(type: .to)
            newPiece.position = CGPoint(x: CGFloat(i-4)*align, y: CGFloat(4)*align)
            newPiece.userInteractionEnabled = true
            pieceNodeArray.append(newPiece)
            boardNode.addChild(newPiece)
        }
    }
    /*
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
            let sprite = SKSpriteNode(imageNamed:"Spaceship")
            
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            sprite.position = location
            
            let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
            
            sprite.runAction(SKAction.repeatActionForever(action))
            
//            self.addChild(sprite)
        }
    }
    */
    func locationToPoint(point:CGPoint) -> Point {
        return Point(y: 10, x: 10)
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}

extension GameScene:PieceTouchDelegate {
    func touchedPiece(piece: PieceNode) {
        if shougiContnroller.select(piece.point) {
            for cpiece in boardNode.children {
                cpiece.unhover()
            }
            piece.hover()
            for point in shougiContnroller.movablePoints {
                masuNodeArray[point.y][point.x]!.hover()
            }
        }
    }
}
