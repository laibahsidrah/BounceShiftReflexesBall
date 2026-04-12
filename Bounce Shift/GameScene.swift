import SpriteKit
import GameplayKit
import Combine

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var viewModel: GameViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private var ball: SKShapeNode!
    private var lanes: [SKShapeNode] = []
    private var laneLabels: [SKLabelNode] = []
    private var laneIcons: [SKSpriteNode] = []
    private var obstacles: [SKSpriteNode] = []
    private var bonuses: [SKShapeNode] = []
    
    private var lastUpdateTime: TimeInterval = 0
    private var obstacleSpawnTimer: TimeInterval = 0
    private var bonusSpawnTimer: TimeInterval = 0
    private var scoreTimer: TimeInterval = 0
    
    private var isGamePaused = false
    private var currentLaneType: LaneType = .normal
    private var tapCount = 0
    private var lastTapTime: TimeInterval = 0
    private var isLongPressing = false
    private var longPressStartTime: TimeInterval = 0
    
    private var dashHintLabel: SKLabelNode?
    private var controlHintsShown = false
    
    private var gameAreaBottom: CGFloat = 0
    private var gameAreaTop: CGFloat = 0
    private var gameAreaHeight: CGFloat = 0
    private var laneHeight: CGFloat = 0
    
    private struct PhysicsCategory {
        static let ball: UInt32 = 0x1 << 0
        static let obstacle: UInt32 = 0x1 << 1
        static let bonus: UInt32 = 0x1 << 2
        static let lane: UInt32 = 0x1 << 3
    }
    
    init(viewModel: GameViewModel) {
        self.viewModel = viewModel
        super.init(size: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        setupScene()
        setupLanes()
        setupBall()
        setupPhysics()
        setupControlHints()
        bindViewModel()
    }
    
    private func setupScene() {
        backgroundColor = .black
        
        let topPadding: CGFloat = 100
        let bottomPadding: CGFloat = 70
        
        gameAreaBottom = bottomPadding
        gameAreaTop = size.height - topPadding
        gameAreaHeight = gameAreaTop - gameAreaBottom
        laneHeight = gameAreaHeight / CGFloat(GameConfig.numberOfLanes)
    }
    
    private func setupLanes() {
        for i in 0..<GameConfig.numberOfLanes {
            let laneType = LaneType(rawValue: i) ?? .normal
            let laneY = gameAreaBottom + laneHeight * CGFloat(i) + laneHeight / 2
            
            let lane = SKShapeNode(rectOf: CGSize(width: size.width, height: laneHeight))
            lane.position = CGPoint(x: size.width / 2, y: laneY)
            lane.fillColor = laneType.color.withAlphaComponent(0.3)
            lane.strokeColor = .clear
            lane.zPosition = -1
            lane.name = "lane_\(i)"
            addChild(lane)
            lanes.append(lane)
            
            addLaneIndicator(for: laneType, at: lane.position, laneHeight: laneHeight)
        }
    }
    
    private func addLaneIndicator(for laneType: LaneType, at position: CGPoint, laneHeight: CGFloat) {
        let container = SKNode()
        container.position = CGPoint(x: size.width - 45, y: position.y)
        container.zPosition = 0
        
        let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.fontSize = 10
        labelNode.fontColor = laneType.color.withAlphaComponent(0.7)
        labelNode.horizontalAlignmentMode = .right
        labelNode.verticalAlignmentMode = .center
        labelNode.position = CGPoint(x: -18, y: 0)
        
        let iconLabel = SKLabelNode(fontNamed: "Helvetica")
        iconLabel.fontSize = 14
        iconLabel.horizontalAlignmentMode = .center
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 5, y: 0)
        
        switch laneType {
        case .normal:
            iconLabel.text = "●"
            iconLabel.fontColor = .systemBlue
            labelNode.text = "NORMAL"
        case .speed:
            iconLabel.text = "⚡"
            labelNode.text = "FAST"
        case .slow:
            iconLabel.text = "🐢"
            labelNode.text = "SLOW"
        case .inverted:
            iconLabel.text = "🔄"
            labelNode.text = "FLIP"
        }
        
        container.addChild(labelNode)
        container.addChild(iconLabel)
        addChild(container)
        laneLabels.append(labelNode)
    }
    
    private func setupBall() {
        ball = SKShapeNode(circleOfRadius: GameConfig.ballRadius)
        ball.fillColor = .white
        ball.strokeColor = .cyan
        ball.lineWidth = 3
        ball.glowWidth = 5
        
        ball.position = CGPoint(
            x: size.width * 0.2,
            y: getLaneY(for: viewModel.currentLane)
        )
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: GameConfig.ballRadius)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.bonus
        ball.physicsBody?.collisionBitMask = 0
        ball.zPosition = 10
        
        addChild(ball)
        
        addPulseEffect(to: ball)
    }
    
    private func getLaneY(for laneIndex: Int) -> CGFloat {
        return gameAreaBottom + laneHeight * CGFloat(laneIndex) + laneHeight / 2
    }
    
    private func setupControlHints() {
        guard !controlHintsShown else { return }
        
        let hintY = gameAreaBottom + gameAreaHeight * 0.5
        
        let hintBackground = SKShapeNode(rectOf: CGSize(width: 220, height: 60), cornerRadius: 10)
        hintBackground.fillColor = UIColor.black.withAlphaComponent(0.7)
        hintBackground.strokeColor = .clear
        hintBackground.position = CGPoint(x: size.width / 2, y: hintY)
        hintBackground.zPosition = 99
        hintBackground.alpha = 0
        addChild(hintBackground)
        
        let jumpHint = SKLabelNode(fontNamed: "Helvetica-Bold")
        jumpHint.text = "Double Tap → Jump"
        jumpHint.fontSize = 13
        jumpHint.fontColor = .yellow.withAlphaComponent(0.9)
        jumpHint.horizontalAlignmentMode = .center
        jumpHint.position = CGPoint(x: size.width / 2, y: hintY + 10)
        jumpHint.zPosition = 100
        jumpHint.alpha = 0
        addChild(jumpHint)
        
        let rushHint = SKLabelNode(fontNamed: "Helvetica-Bold")
        rushHint.text = "Hold → Rush (x2 points)"
        rushHint.fontSize = 13
        rushHint.fontColor = .orange.withAlphaComponent(0.9)
        rushHint.horizontalAlignmentMode = .center
        rushHint.position = CGPoint(x: size.width / 2, y: hintY - 12)
        rushHint.zPosition = 100
        rushHint.alpha = 0
        addChild(rushHint)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 3.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        
        hintBackground.run(sequence)
        jumpHint.run(sequence)
        rushHint.run(sequence)
        
        controlHintsShown = true
    }
    
    private func addPulseEffect(to node: SKNode) {
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        node.run(SKAction.repeatForever(pulse))
    }
    
    private func setupPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }
    
    private func bindViewModel() {
        viewModel.$gameState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.handleGameStateChange(state)
            }
            .store(in: &cancellables)
        
        viewModel.$currentLane
            .receive(on: RunLoop.main)
            .sink { [weak self] lane in
                self?.moveBallToLane(lane)
            }
            .store(in: &cancellables)
    }
    
    private func handleGameStateChange(_ state: GameState) {
        switch state {
        case .playing:
            isGamePaused = false
            isPaused = false
        case .paused:
            isGamePaused = true
            isPaused = true
        case .gameOver:
            isGamePaused = true
        default:
            break
        }
    }
    
    private func moveBallToLane(_ lane: Int) {
        let targetY = getLaneY(for: lane)
        
        let moveAction = SKAction.moveTo(y: targetY, duration: 0.15)
        moveAction.timingMode = .easeOut
        ball.run(moveAction)
        
        currentLaneType = LaneType(rawValue: lane) ?? .normal
        updateBallColor()
        showLaneChangeEffect(lane)
        SoundService.shared.playLaneChange()
    }
    
    private func showLaneChangeEffect(_ lane: Int) {
        let laneType = LaneType(rawValue: lane) ?? .normal
        
        let effectLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        effectLabel.fontSize = 14
        effectLabel.fontColor = laneType.color
        effectLabel.horizontalAlignmentMode = .center
        
        let safeX = max(size.width / 2, ball.position.x + 60)
        effectLabel.position = CGPoint(x: safeX, y: ball.position.y + 10)
        effectLabel.zPosition = 50
        
        switch laneType {
        case .normal:
            effectLabel.text = "Normal"
        case .speed:
            effectLabel.text = "Speed Up!"
        case .slow:
            effectLabel.text = "Slow Down"
        case .inverted:
            effectLabel.text = "Inverted!"
        }
        
        addChild(effectLabel)
        
        let moveUp = SKAction.moveBy(x: 0, y: 25, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        
        effectLabel.run(SKAction.sequence([group, remove]))
    }
    
    private func updateBallColor() {
        let transition = SKAction.colorize(
            with: currentLaneType.color,
            colorBlendFactor: 0.5,
            duration: 0.2
        )
        ball.run(transition)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGamePaused else { return }
        
        let currentTime = CACurrentMediaTime()
        
        if currentTime - lastTapTime < 0.3 {
            tapCount += 1
        } else {
            tapCount = 1
        }
        lastTapTime = currentTime
        
        longPressStartTime = currentTime
        isLongPressing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self, self.isLongPressing, self.tapCount == 1 else { return }
            self.startRushMode()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGamePaused else { return }
        
        let pressDuration = CACurrentMediaTime() - longPressStartTime
        isLongPressing = false
        
        if viewModel.isRushing {
            endRushMode()
            return
        }
        
        if pressDuration < 0.25 {
            if tapCount >= 2 {
                handleDoubleTap()
                tapCount = 0
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    guard let self = self else { return }
                    if self.tapCount == 1 && !self.viewModel.isRushing {
                        self.handleSingleTap(touches)
                    }
                    self.tapCount = 0
                }
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isLongPressing = false
        if viewModel.isRushing {
            endRushMode()
        }
    }
    
    private func handleSingleTap(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let direction = location.y > ball.position.y ? 1 : -1
        viewModel.changeLane(direction: direction, isInverted: currentLaneType.isInverted)
    }
    
    private func handleDoubleTap() {
        viewModel.performJump()
        performJumpAnimation()
        showJumpEffect()
        SoundService.shared.playJump()
    }
    
    private func startRushMode() {
        guard !viewModel.isRushing else { return }
        viewModel.startRush()
        SoundService.shared.playDash()
        
        let rushPosition = size.width * 0.4
        let moveForward = SKAction.moveTo(x: rushPosition, duration: 0.2)
        moveForward.timingMode = .easeOut
        ball.run(moveForward, withKey: "rush")
        
        showRushEffect()
        startRushGlow()
    }
    
    private func endRushMode() {
        viewModel.endRush()
        
        ball.removeAction(forKey: "rush")
        ball.removeAction(forKey: "rushGlow")
        
        let normalPosition = size.width * 0.2
        let moveBack = SKAction.moveTo(x: normalPosition, duration: 0.15)
        moveBack.timingMode = .easeIn
        ball.run(moveBack)
        
        ball.glowWidth = 5
    }
    
    private func showRushEffect() {
        let rushLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        rushLabel.text = "RUSH x2!"
        rushLabel.fontSize = 16
        rushLabel.fontColor = .orange
        rushLabel.horizontalAlignmentMode = .center
        rushLabel.position = CGPoint(x: size.width / 2, y: ball.position.y + 35)
        rushLabel.zPosition = 100
        addChild(rushLabel)
        
        let moveUp = SKAction.moveBy(x: 0, y: 20, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        
        rushLabel.run(SKAction.sequence([group, remove]))
    }
    
    private func startRushGlow() {
        let glowUp = SKAction.customAction(withDuration: 0.3) { node, time in
            if let shape = node as? SKShapeNode {
                shape.glowWidth = 5 + CGFloat(time / 0.3) * 10
            }
        }
        let glowDown = SKAction.customAction(withDuration: 0.3) { node, time in
            if let shape = node as? SKShapeNode {
                shape.glowWidth = 15 - CGFloat(time / 0.3) * 10
            }
        }
        let pulse = SKAction.sequence([glowUp, glowDown])
        ball.run(SKAction.repeatForever(pulse), withKey: "rushGlow")
    }
    
    private func showJumpEffect() {
        let jumpLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        jumpLabel.text = "JUMP!"
        jumpLabel.fontSize = 16
        jumpLabel.fontColor = .yellow
        jumpLabel.horizontalAlignmentMode = .center
        jumpLabel.position = CGPoint(x: size.width / 2, y: ball.position.y + 35)
        jumpLabel.zPosition = 100
        addChild(jumpLabel)
        
        let duration = GameConfig.jumpDuration
        let moveUp = SKAction.moveBy(x: 0, y: 25, duration: duration * 0.4)
        let stay = SKAction.wait(forDuration: duration * 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: duration * 0.4)
        let moveDown = SKAction.moveBy(x: 0, y: -10, duration: duration * 0.4)
        let group = SKAction.group([fadeOut, moveDown])
        let remove = SKAction.removeFromParent()
        
        jumpLabel.run(SKAction.sequence([moveUp, stay, group, remove]))
    }
    
    private func performJumpAnimation() {
        let duration = GameConfig.jumpDuration
        
        let shadow = ball.copy() as! SKShapeNode
        shadow.fillColor = .gray
        shadow.strokeColor = .clear
        shadow.alpha = 0.4
        shadow.glowWidth = 0
        shadow.zPosition = ball.zPosition - 1
        shadow.setScale(0.8)
        addChild(shadow)
        
        let jumpUp = SKAction.group([
            SKAction.scale(to: 1.4, duration: duration * 0.3),
            SKAction.moveBy(x: 0, y: 15, duration: duration * 0.3)
        ])
        jumpUp.timingMode = .easeOut
        
        let float = SKAction.group([
            SKAction.scale(to: 1.5, duration: duration * 0.4),
            SKAction.moveBy(x: 0, y: 5, duration: duration * 0.2)
        ])
        
        let jumpDown = SKAction.group([
            SKAction.scale(to: 1.0, duration: duration * 0.3),
            SKAction.moveBy(x: 0, y: -20, duration: duration * 0.3)
        ])
        jumpDown.timingMode = .easeIn
        
        ball.run(SKAction.sequence([jumpUp, float, jumpDown]))
        
        let glowEffect = SKAction.sequence([
            SKAction.customAction(withDuration: duration) { node, time in
                if let shape = node as? SKShapeNode {
                    let progress = time / CGFloat(duration)
                    if progress < 0.3 {
                        shape.glowWidth = 5 + progress * 30
                        shape.strokeColor = .yellow
                    } else if progress < 0.7 {
                        shape.glowWidth = 15
                        shape.strokeColor = .yellow
                    } else {
                        shape.glowWidth = 15 - (progress - 0.7) * 30
                        shape.strokeColor = .cyan
                    }
                }
            },
            SKAction.run { [weak self] in
                self?.ball.glowWidth = 5
                self?.ball.strokeColor = .cyan
            }
        ])
        ball.run(glowEffect, withKey: "jumpGlow")
        
        let shrink = SKAction.scale(to: 0.5, duration: duration)
        let fade = SKAction.fadeOut(withDuration: duration)
        let shadowAction = SKAction.group([shrink, fade])
        shadow.run(SKAction.sequence([shadowAction, SKAction.removeFromParent()]))
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard !isGamePaused else { return }
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        updateObstacles(deltaTime)
        updateBonuses(deltaTime)
        spawnElements(deltaTime)
        updateScore(deltaTime)
        
        viewModel.increaseSpeed()
    }
    
    private func updateObstacles(_ deltaTime: TimeInterval) {
        let speed = viewModel.currentSpeed * currentLaneType.speedMultiplier
        
        for obstacle in obstacles {
            obstacle.position.x -= speed * CGFloat(deltaTime)
            
            if obstacle.position.x < -50 {
                obstacle.removeFromParent()
                obstacles.removeAll { $0 == obstacle }
                viewModel.avoidObstacle()
            }
        }
    }
    
    private func updateBonuses(_ deltaTime: TimeInterval) {
        let speed = viewModel.currentSpeed * currentLaneType.speedMultiplier
        
        for bonus in bonuses {
            bonus.position.x -= speed * CGFloat(deltaTime)
            
            if bonus.position.x < -50 {
                bonus.removeFromParent()
                bonuses.removeAll { $0 == bonus }
            }
        }
    }
    
    private func spawnElements(_ deltaTime: TimeInterval) {
        obstacleSpawnTimer += deltaTime
        bonusSpawnTimer += deltaTime
        
        let speedFactor = Double(viewModel.currentSpeed - 150) / 100
        let obstacleInterval = max(1.0, viewModel.obstacleSpawnInterval - speedFactor * 0.3)
        let bonusInterval = viewModel.bonusSpawnInterval
        
        if obstacleSpawnTimer >= obstacleInterval {
            spawnObstacle()
            obstacleSpawnTimer = 0
        }
        
        if bonusSpawnTimer >= bonusInterval {
            spawnBonus()
            bonusSpawnTimer = 0
        }
    }
    
    private func spawnObstacle() {
        let laneIndex = Int.random(in: 0..<GameConfig.numberOfLanes)
        let obstacleHeight = laneHeight * 0.6
        let obstacleWidth = GameConfig.obstacleWidth
        
        let container = SKSpriteNode(color: .clear, size: CGSize(width: obstacleWidth, height: obstacleHeight))
        container.position = CGPoint(
            x: size.width + obstacleWidth,
            y: getLaneY(for: laneIndex)
        )
        
        let obstacleShape = SKShapeNode(rectOf: CGSize(width: obstacleWidth, height: obstacleHeight), cornerRadius: 8)
        obstacleShape.fillColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        obstacleShape.strokeColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        obstacleShape.lineWidth = 2
        obstacleShape.glowWidth = 3
        container.addChild(obstacleShape)
        
        let stripe1 = SKShapeNode(rectOf: CGSize(width: 4, height: obstacleHeight * 0.6))
        stripe1.fillColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.6)
        stripe1.strokeColor = .clear
        stripe1.position = CGPoint(x: -obstacleWidth * 0.25, y: 0)
        container.addChild(stripe1)
        
        let stripe2 = SKShapeNode(rectOf: CGSize(width: 4, height: obstacleHeight * 0.6))
        stripe2.fillColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.6)
        stripe2.strokeColor = .clear
        stripe2.position = CGPoint(x: obstacleWidth * 0.25, y: 0)
        container.addChild(stripe2)
        
        let skull = SKLabelNode(text: "☠️")
        skull.fontSize = min(obstacleHeight * 0.5, 24)
        skull.verticalAlignmentMode = .center
        skull.horizontalAlignmentMode = .center
        skull.position = CGPoint(x: 0, y: 0)
        container.addChild(skull)
        
        container.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: obstacleWidth, height: obstacleHeight))
        container.physicsBody?.isDynamic = false
        container.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        container.zPosition = 5
        
        let pulse = SKAction.sequence([
            SKAction.run { obstacleShape.glowWidth = 5 },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { obstacleShape.glowWidth = 2 },
            SKAction.wait(forDuration: 0.3)
        ])
        obstacleShape.run(SKAction.repeatForever(pulse))
        
        addChild(container)
        obstacles.append(container)
    }
    
    private func spawnBonus() {
        let laneIndex = Int.random(in: 0..<GameConfig.numberOfLanes)
        
        let bonus = SKShapeNode(circleOfRadius: GameConfig.bonusSize / 2)
        bonus.fillColor = .yellow
        bonus.strokeColor = .orange
        bonus.lineWidth = 2
        bonus.glowWidth = 3
        bonus.position = CGPoint(
            x: size.width + GameConfig.bonusSize,
            y: getLaneY(for: laneIndex)
        )
        
        bonus.physicsBody = SKPhysicsBody(circleOfRadius: GameConfig.bonusSize / 2)
        bonus.physicsBody?.isDynamic = false
        bonus.physicsBody?.categoryBitMask = PhysicsCategory.bonus
        bonus.zPosition = 5
        
        let starLabel = SKLabelNode(fontNamed: "Helvetica")
        starLabel.text = "★"
        starLabel.fontSize = 14
        starLabel.fontColor = .orange
        starLabel.verticalAlignmentMode = .center
        bonus.addChild(starLabel)
        
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 1)
        bonus.run(SKAction.repeatForever(rotate))
        
        addChild(bonus)
        bonuses.append(bonus)
    }
    
    private func updateScore(_ deltaTime: TimeInterval) {
        scoreTimer += deltaTime
        if scoreTimer >= 0.1 {
            viewModel.addScore(1)
            scoreTimer = 0
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == PhysicsCategory.ball | PhysicsCategory.obstacle {
            if !viewModel.isJumping {
                handleCollision()
            }
        } else if collision == PhysicsCategory.ball | PhysicsCategory.bonus {
            handleBonusCollection(contact)
        }
    }
    
    private func handleCollision() {
        let flash = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 1, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
        ])
        ball.run(SKAction.repeat(flash, count: 3))
        
        SoundService.shared.playObstacleHit()
        SoundService.shared.playGameOver()
        viewModel.endGame()
    }
    
    private func handleBonusCollection(_ contact: SKPhysicsContact) {
        let bonusNode = contact.bodyA.categoryBitMask == PhysicsCategory.bonus ?
            contact.bodyA.node : contact.bodyB.node
        
        if let bonus = bonusNode as? SKShapeNode {
            let scaleUp = SKAction.scale(to: 1.5, duration: 0.1)
            let fadeOut = SKAction.fadeOut(withDuration: 0.1)
            let remove = SKAction.removeFromParent()
            
            bonus.run(SKAction.sequence([scaleUp, fadeOut, remove]))
            bonuses.removeAll { $0 == bonus }
            
            viewModel.addScore(50)
            viewModel.collectBonus()
            
            showBonusCollectedEffect()
            SoundService.shared.playBonusCollected()
        }
    }
    
    private func showBonusCollectedEffect() {
        let bonusLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        bonusLabel.text = "+50"
        bonusLabel.fontSize = 18
        bonusLabel.fontColor = .yellow
        bonusLabel.horizontalAlignmentMode = .center
        bonusLabel.position = CGPoint(x: size.width / 2, y: ball.position.y + 35)
        bonusLabel.zPosition = 100
        addChild(bonusLabel)
        
        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        
        bonusLabel.run(SKAction.sequence([group, remove]))
    }
}
