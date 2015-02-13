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
    func pieceTouchesBegan(piece:PieceNode)
    func pieceTouchesMoved(piece:PieceNode, touches: NSSet, withEvent event: UIEvent)
    func pieceTouchesEnded(piece:PieceNode)
}

class PieceNode: SKSpriteNode {
    enum Type: String {
        case ho = "koma_ho.png"
        case to = "koma_to_r.png"
        case hoh = "koma_ho_hover.png"
        case toh = "koma_to_hover_r.png"
        case masu = "masu.png"
        case masuh = "masu_hover.png"
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
        _willMove = false
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
        _willMove = false
        super.init(coder: aDecoder)
    }
    
    func hover() {
        switch piecetype! {
        case .ho:
            piecetype = .hoh
        case .to:
            piecetype = .toh
        case .masu:
            piecetype = .masuh
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
        case .masuh:
            piecetype = .masu
            self.hidden = true
        default:
            break
        }
    }
    
    var _position : CGPoint?
    var _willMove : Bool
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            _position = self.position
            _willMove = false
        }
        delegate?.pieceTouchesBegan(self)
    }
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if self.piecetype == .masu {
            return
        }
        if !_willMove {
            for touch: AnyObject in touches {
                let location = touch.locationInNode(self.parent)
                let x = location.x - _position!.x
                let y = location.y - _position!.y
                if sqrt(x*x + y*y) > 20 {
                    _willMove = true
                }
            }
        } else {
            delegate?.pieceTouchesMoved(self, touches: touches, withEvent: event)
        }
    }
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        for touch: AnyObject in touches {
            delegate?.pieceTouchesEnded(self)

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
    var hoNodeArray: [PieceNode?]
    var toNodeArray: [PieceNode?]
    var selectedPieceNode: PieceNode?
    
    required init?(coder aDecoder: NSCoder) {
        shougiContnroller = ShougiController()
        boardNode = SKSpriteNode(imageNamed: "ban.png")
        boardNode.xScale = SCALE
        boardNode.yScale = SCALE
        masuNodeArray = Array(count: 9, repeatedValue: Array(count: 9, repeatedValue: nil))
        hoNodeArray = Array()
        toNodeArray = Array()
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
                newPiece.point = Point(y: i, x: j)
                newPiece.delegate = self
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
            hoNodeArray.append(newPiece)
            boardNode.addChild(newPiece)
        }
        for i in 0...8 {
            var newPiece : PieceNode = PieceNode(type: .to)
            newPiece.position = CGPoint(x: CGFloat(i-4)*align, y: CGFloat(4)*align)
            newPiece.userInteractionEnabled = true
            newPiece.delegate = self
            newPiece.point = Point(y: 0, x: i)
            toNodeArray.append(newPiece)
            boardNode.addChild(newPiece)
        }
    }

    func locationToPoint(point:CGPoint) -> Point {
        return Point(y: 10, x: 10)
    }
   
    override func update(currentTime: CFTimeInterval) {
        for cpiece in boardNode.children {
            cpiece.unhover()
        }
        for point in shougiContnroller.movablePoints {
            let masuNode = masuNodeArray[point.y][point.x]!
                masuNode.hover()
        }
        if let piece = shougiContnroller.selectedPiece() {
            switch piece.type {
            case .Ho:
                hoNodeArray[piece.id]?.hover()
                break
            case .To:
                toNodeArray[piece.id]?.hover()
                break
            default:
                break
            }
        }
    }
}

extension GameScene:PieceTouchDelegate {
    func pieceTouchesBegan(piece: PieceNode) {
        if piece.piecetype == .masuh {
            movePiece(piece, duration: 0.2)
            return
        }
        if let sPiece = shougiContnroller.selectedPiece() {
            if pieceNode(sPiece) == piece {
                shougiContnroller.unselect()
            }
        } else {
            if shougiContnroller.select(piece.point) {
                selectedPieceNode = piece
                return
            }
        }
        shougiContnroller.unselect()
    }
    func pieceTouchesEnded(piece: PieceNode) {
        for point in shougiContnroller.movablePoints {
            let masuNode = masuNodeArray[point.y][point.x]!
            
            if masuNode.containsPoint(selectedPieceNode!.position) {
                movePiece(masuNode, duration: 0.0)
                return
            }
        }
        piece.position = piece._position!
    }
    func pieceTouchesMoved(piece: PieceNode, touches: NSSet, withEvent event: UIEvent) {
        if !shougiContnroller.select(piece.point) {
            return
        }
        for touch: AnyObject in touches {
            let location = touch.locationInNode(piece.parent)
            piece.position = CGPointMake(location.x, location.y + 62)
        }
    }
    func movePiece(piece: PieceNode, duration: NSTimeInterval) -> Bool {
        if shougiContnroller.movePiece(piece.point!) {
            selectedPieceNode?.point = piece.point
            let action = SKAction.moveTo(piece.position, duration: duration)
            selectedPieceNode?.runAction(action, completion:{
                self.updatePiece()
            })
            return true
        }
        return false
    }
    func updatePiece() {
        for piece in hoNodeArray {
            if shougiContnroller.piece(piece!.point!).type == .Masu {
                let moveAction = SKAction.moveBy(CGVector(dx: 0, dy: 1000), duration: 0.3)
                piece?.runAction(moveAction)
            }
        }
        for piece in toNodeArray {
            if shougiContnroller.piece(piece!.point!).type == .Masu {
                let moveAction = SKAction.moveBy(CGVector(dx: 0, dy: -1000), duration: 0.3)
                piece?.runAction(moveAction)
            }
        }
    }
    func pieceNode(piece: Piece) -> PieceNode? {
        switch piece.type {
        case .Ho:
            return hoNodeArray[piece.id]
        case .To:
            return toNodeArray[piece.id]
        default:
            return nil
        }
    }
}
