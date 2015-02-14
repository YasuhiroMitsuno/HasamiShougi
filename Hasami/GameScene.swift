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
        if self.piecetype == .masu || self.piecetype == .masuh {
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

protocol SKButtonDelegate {
    func action()
}

class SKButtonNode: SKLabelNode {
    var delegate: SKButtonDelegate?
    override init(fontNamed fontName: String!) {
        super.init(fontNamed: fontName)
    }
    override init() {
        super.init()
        self.userInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        delegate?.action()
    }
}

class GameScene: SKScene {
    var shougiContnroller: ShougiController
    var masuNodeArray: [[PieceNode?]]
    var boardNode: SKSpriteNode
    var hoNodeArray: [PieceNode?]
    var toNodeArray: [PieceNode?]
    var selectedPieceNode: PieceNode?
    var mattaLabel: SKButtonNode
    
    required init?(coder aDecoder: NSCoder) {
        shougiContnroller = ShougiController()
        boardNode = SKSpriteNode(imageNamed: "ban.png")
        boardNode.xScale = SCALE
        boardNode.yScale = SCALE
        masuNodeArray = Array(count: 9, repeatedValue: Array(count: 9, repeatedValue: nil))
        mattaLabel = SKButtonNode(fontNamed:"Chalkduster")
        hoNodeArray = Array()
        toNodeArray = Array()
        isRunningAction = false
        srandomdev()
        super.init(coder: aDecoder)
    }
    override func didMoveToView(view: SKView) {
        boardNode.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        boardNode.zPosition = 0
        self.addChild(boardNode)
        
        mattaLabel.text = "matta!";
        mattaLabel.fontSize = 50;
        mattaLabel.position = CGPoint(x:400, y:100);
        mattaLabel.delegate = self
        self.addChild(mattaLabel)

        for i in 0...8 {
            for j in 0...8 {
                var newPiece : PieceNode = PieceNode(type: .masu)
                newPiece.position = CGPoint(x: CGFloat(j-4)*align, y: CGFloat(4-i)*align)
                newPiece.userInteractionEnabled = true
                newPiece.hidden = true
                newPiece.point = Point(y: i, x: j)
                newPiece.delegate = self
                newPiece.zPosition = 1
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
            newPiece.zPosition = 2
            hoNodeArray.append(newPiece)
            boardNode.addChild(newPiece)
        }
        for i in 0...8 {
            var newPiece : PieceNode = PieceNode(type: .to)
            newPiece.position = CGPoint(x: CGFloat(i-4)*align, y: CGFloat(4)*align)
            newPiece.userInteractionEnabled = true
            newPiece.delegate = self
            newPiece.point = Point(y: 0, x: i)
            newPiece.zPosition = 2
            toNodeArray.append(newPiece)
            boardNode.addChild(newPiece)
        }
    }

    func locationToPoint(point:CGPoint) -> Point {
        return Point(y: 10, x: 10)
    }
   
    var isRunningAction: Bool
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

        if shougiContnroller.currentPlayer == .Enemy && !isRunningAction {
            var r = random()%9
            pieceTouchesBegan(toNodeArray[r]!)
            var c = shougiContnroller.movablePoints.count
            if c != 0 {
                var p = shougiContnroller.movablePoints[random()%c]
                movePiece(masuNodeArray[p.y][p.x]!, duration: 0.1)
            }

        }
        /*
        if shougiContnroller.currentPlayer == .Own && !isRunningAction {
            var r = random()%9
            pieceTouchesBegan(hoNodeArray[r]!)
            var c = shougiContnroller.movablePoints.count
            if c != 0 {
                var p = shougiContnroller.movablePoints[random()%c]
                movePiece(masuNodeArray[p.y][p.x]!, duration: 0.1)
            }
            
        }
*/
        if let winner = shougiContnroller.winner() {
            NSLog("\(winner)")
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
            updatePiece()
/*
            let moveaction = SKAction.moveTo(piece.position, duration: duration)
            let action = SKAction.sequence([moveaction, SKAction.waitForDuration(0.2)])
            isRunningAction = true
            selectedPieceNode?.runAction(moveaction, completion:{
                self.isRunningAction = false
                self.updatePiece()
            })
*/
            return true
        }
        return false
    }
    func updatePiece() {
        for T in masuNodeArray {
            for masuNode in T {
                let piece = shougiContnroller.piece(masuNode!.point!)
                switch piece.type {
                case .Ho:
                    let moveAction = SKAction.moveTo(masuNode!.position, duration: 0.2)
                    isRunningAction = true
                    hoNodeArray[piece.id]?.point = masuNode?.point
                    hoNodeArray[piece.id]!.runAction(moveAction, completion: {
                        self.isRunningAction = false

                    })
                    break
                case .To:
                    let moveAction = SKAction.moveTo(masuNode!.position, duration: 0.2)
                    isRunningAction = true
                    toNodeArray[piece.id]?.point = masuNode?.point
                    toNodeArray[piece.id]!.runAction(moveAction, completion: {
                        self.isRunningAction = false

                    })
                    break
                default:
                    break
                }
            }
        }
        /*
        for piece in hoNodeArray {
            if shougiContnroller.piece(piece!.point!).type == .Masu {
                let moveAction = SKAction.moveBy(CGVector(dx: 0, dy: 1000), duration: 0.0)
  //              isRunningAction = true
                piece?.runAction(moveAction, completion: {
      //              self.isRunningAction = false
                })
            }
        }
        for piece in toNodeArray {
            if shougiContnroller.piece(piece!.point!).type == .Masu {
                let moveAction = SKAction.moveBy(CGVector(dx: 0, dy: -1000), duration: 0.0)
  //              isRunningAction = true
                piece?.runAction(moveAction, completion: {
   //                 self.isRunningAction = false
                })
            }
        }
*/
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

extension GameScene: SKButtonDelegate {
    func action() {
        matta()
    }
    func matta() {
        shougiContnroller.matta()
        updatePiece()
    }
}
