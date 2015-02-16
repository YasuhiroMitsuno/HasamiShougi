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
        case hor = "koma_ho_r.png"
        case tor = "koma_to.png"
        case masu = "masu.png"
        case masuh = "masu_hover.png"
    }
    var point : Point?
    var _position : CGPoint?
    var _willMove : Bool
    var piecetype : Type? {
        didSet {
            self.texture = SKTexture(imageNamed: piecetype!.rawValue)
        }
    }
    var excluded: Bool {
        didSet {
            if excluded {
                switch piecetype! {
                case .ho:
                    piecetype = .hor
                case .to:
                    piecetype = .tor
                default:
                    break
                }
            } else {
                switch piecetype! {
                case .hor:
                    piecetype = .ho
                case .tor:
                    piecetype = .to
                default:
                    break
                }
            }
        }
    }
    var delegate : PieceTouchDelegate?
    
    override init(texture: SKTexture!, color: UIColor!, size: CGSize)
    {
        _willMove = false
        excluded = false
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
        excluded = false
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
    var pieceNodeArray: [[PieceNode?]]
    var selectedPieceNode: PieceNode?
    var mattaLabel: SKButtonNode
    var actionCount: Int
    var excludedPieces: [Int]
    let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    let indicator: UIActivityIndicatorView
    
    required init?(coder aDecoder: NSCoder) {
        shougiContnroller = ShougiController()
        boardNode = SKSpriteNode(imageNamed: "ban.png")
        boardNode.xScale = SCALE
        boardNode.yScale = SCALE
        masuNodeArray = Array(count: 9, repeatedValue: Array(count: 9, repeatedValue: nil))
        mattaLabel = SKButtonNode(fontNamed:"Chalkduster")
        pieceNodeArray = Array(count: 2, repeatedValue: Array())
        excludedPieces = Array(count: 2, repeatedValue: 0)
        isRunningAction = false
        isThread = false
        actionCount = 0
        indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        super.init(coder: aDecoder)
    }
    override func didMoveToView(view: SKView) {
        boardNode.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        boardNode.zPosition = 0
        self.addChild(boardNode)
        

        
        mattaLabel.text = "matta!";
        mattaLabel.fontSize = 50;
        mattaLabel.position = CGPoint(x:400, y:50);
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
            pieceNodeArray[0].append(newPiece)
            boardNode.addChild(newPiece)
        }
        for i in 0...8 {
            var newPiece : PieceNode = PieceNode(type: .to)
            newPiece.position = CGPoint(x: CGFloat(i-4)*align, y: CGFloat(4)*align)
            newPiece.userInteractionEnabled = true
            newPiece.delegate = self
            newPiece.point = Point(y: 0, x: i)
            newPiece.zPosition = 2
            pieceNodeArray[1].append(newPiece)
            boardNode.addChild(newPiece)
        }
        indicator.center = self.view!.center
        self.view!.addSubview(indicator)
    }
    

    func locationToPoint(point:CGPoint) -> Point {
        return Point(y: 10, x: 10)
    }
   
    var isRunningAction: Bool
    var isThread: Bool
    override func update(currentTime: CFTimeInterval) {
        if isThread || isRunningAction {
            return
        }
        if let winner = shougiContnroller.winner() {
            shougiContnroller.reset()
            updatePiece(0.2)
        }
        for cpiece in boardNode.children {
            cpiece.unhover()
        }

        for point in shougiContnroller.movablePoints {
            let masuNode = masuNodeArray[point.y][point.x]!
                masuNode.hover()
        }

        if let piece = shougiContnroller.selectedPiece() {
            if piece.type != .Masu {
                pieceNodeArray[piece.type.rawValue][piece.id]?.hover()
            }
        }

        if shougiContnroller.currentPlayer() == .Enemy {
            isThread = true
            indicator.startAnimating()
            dispatch_async(backgroundQueue, {
                self.shougiContnroller.algorithm()
                dispatch_async(dispatch_get_main_queue()) {
                    self.updatePiece(0.2)
                    self.isThread = false
                    self.indicator.stopAnimating()
                }
            })
        }

/*
        if shougiContnroller.currentPlayer() == .Own && !isRunningAction {
            isThread = true
            indicator.startAnimating()
            dispatch_async(backgroundQueue, {
                self.shougiContnroller.algorithm()
                dispatch_async(dispatch_get_main_queue()) {
                    self.updatePiece(0.2)
                    self.isThread = false
                    self.indicator.stopAnimating()
                }
            })
        }
*/
    }
}

extension GameScene:PieceTouchDelegate {
    func pieceTouchesBegan(piece: PieceNode) {
        if isThread || isRunningAction {
            return
        }
        if piece.piecetype == .masuh {
            movePiece(piece, duration: 0.2)
            return
        }
        if let sPiece = shougiContnroller.selectedPiece() {
            if pieceNode(sPiece) == piece {
                shougiContnroller.unselect()
            } else if shougiContnroller.select(piece.point) {
                selectedPieceNode = piece
                return
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
        if isThread || isRunningAction {
            return
        }
        
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
        if isThread || isRunningAction {
            return
        }
        
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
//            selectedPieceNode?.point = piece.point
            updatePiece(duration)
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
    
    func appendAction() {
        isRunningAction = true
        actionCount++
    }
    func compeleAction() {
        if --actionCount == 0 {
            isRunningAction = false
        }
    }
    
    func excludePiece(piece: PieceNode, duration: NSTimeInterval) {
        if piece.piecetype == .ho {
            let moveAction = SKAction.moveTo(CGPointMake(-250 + CGFloat(excludedPieces[0] * 62), 360), duration: 0.2)
            let action = SKAction.sequence([SKAction.waitForDuration(duration), moveAction])
            appendAction()
            piece.runAction(action, completion: {
                self.compeleAction()
                piece.excluded = true
            })
            excludedPieces[0]++

        }
        if piece.piecetype == .to {
            let moveAction = SKAction.moveTo(CGPointMake(250 + CGFloat(excludedPieces[1] * -62), -360), duration: 0.2)
            let action = SKAction.sequence([SKAction.waitForDuration(duration), moveAction])
            appendAction()
            piece.runAction(action, completion: {
                self.compeleAction()
                piece.excluded = true
            })
            excludedPieces[1]++

        }
        piece.point = Point(y: -1, x: -1)
        
    }
    func updatePiece(duration: NSTimeInterval) {
        for T in masuNodeArray {
            for masuNode in T {
                let piece = shougiContnroller.piece(masuNode!.point!)
                if piece.type == .Masu {
                    continue
                }
                if pieceNodeArray[piece.type.rawValue][piece.id]!.point! == masuNode!.point! {
                    continue
                }
                let moveAction = SKAction.moveTo(masuNode!.position, duration: duration)
                let action = SKAction.sequence([moveAction, SKAction.waitForDuration(0.0)])
                appendAction()
                pieceNodeArray[piece.type.rawValue][piece.id]?.point = masuNode?.point
                let pNode = pieceNodeArray[piece.type.rawValue][piece.id]!
                if pNode.excluded {
                    switch pNode.piecetype! {
                    case .hor:
                        excludedPieces[0]--
                        break
                    case .tor:
                        excludedPieces[1]--
                        break
                    default:
                        break
                    }
                }
                pNode.excluded = false
                pieceNodeArray[piece.type.rawValue][piece.id]!.runAction(action, completion: {
                    self.compeleAction()
                })
            }
        }

        for T in pieceNodeArray {
            for piece in T {
                if !piece!.excluded && shougiContnroller.piece(piece!.point!).type == PieceType.Masu {
                    excludePiece(piece!, duration: duration)
                }
            }
        }
    }
    func pieceNode(piece: Piece) -> PieceNode? {
        if piece.type == .Masu {
            return nil
        }
        return pieceNodeArray[piece.type.rawValue][piece.id]
    }
}

extension GameScene: SKButtonDelegate {
    func action() {
        if isThread {
            return
        }
        matta()
    }
    func matta() {
        shougiContnroller.matta()

        updatePiece(0.2)
    }
}
