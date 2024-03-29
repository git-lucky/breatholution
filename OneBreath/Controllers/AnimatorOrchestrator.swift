import UIKit

protocol AnimatorOrchestratorDelegate {
    func didBeginBreathingIntro()
    func didBeginMainBreathingSequence(inBreathDuration: Double, outBreathDuration: Double, numberOfCycles: Int)
    func didBeginSilencePeriod()
    func didEndBreathing()
}

class AnimatorOrchestrator {
    
    let delegate: AnimatorOrchestratorDelegate

    private let minScale = 0.7
    private let maxScale = 1.1
    private let numberOfBreathCycles = 6
    private let inBreathDuration = 4.0 //seconds
    private let outBreathDuration = 6.0 //seconds
    private let silenceDuration = 5.0 //seconds
    
    private let breathAnimator: BreathAnimator
    private var breathView: UIView?
    private var instructionsLabel: UILabel?
    
    private var timerForBreathing: Timer?
    
    init(delegate: AnimatorOrchestratorDelegate) {
        self.delegate = delegate
        self.breathAnimator = BreathAnimator(minScale: minScale, maxScale: maxScale, numberOfBreathCycles: numberOfBreathCycles, inBreathDuration: inBreathDuration, outBreathDuration: outBreathDuration)
    }
    
    func beginBreathingSequence(breathView: UIView, onDate: Date, instructionsLabel: UILabel) {
        timerForBreathing?.invalidate()
        
        self.breathView = breathView
        self.instructionsLabel = instructionsLabel
        
        timerForBreathing = Timer(fire: onDate, interval: 0, repeats: false) { (timer) in
            
            self.delegate.didBeginBreathingIntro()
            IntroAnimator.animateIntro(view: breathView, duration: 2, scale: CGFloat(self.minScale))
        }
        RunLoop.main.add(timerForBreathing!, forMode: .common)
    }
    
    func beginMainBreathingSequence() {
        guard let breathView = self.breathView, let instructionsLabel = self.instructionsLabel else { fatalError() }
        self.delegate.didBeginMainBreathingSequence(inBreathDuration: inBreathDuration, outBreathDuration: outBreathDuration, numberOfCycles: numberOfBreathCycles)
        self.breathAnimator.makeBreathe(view: breathView) {
            // show silence animation
            instructionsLabel.text = "Be still and allow\nthe past minute to soak in\n\nFeel your intentions being fulfilled\nand share them with the universe"
            UIView.animate(withDuration: 0.5, animations: {
                instructionsLabel.alpha = 1
            })
            let date = Date(timeInterval: self.silenceDuration, since: Date())
            let timer = Timer(fire: date, interval: 0, repeats: false) { (_) in
                UIView.animate(withDuration: 0.5, animations: {
                    instructionsLabel.alpha = 0
                })
                self.delegate.didEndBreathing()
            }
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    // NOTE: I should create an array of messages I want played on every in and out breath in sequence and then when the trough or crest is reached, it looks to see what/if the next message is.
    func animateInstructions() {
        guard let instructionsLabel = self.instructionsLabel else { return }
//        instructionsLabel.text = "Be still and bring your\nattention to your breath"
//        UIView.animate(withDuration: 0.5) {
//            instructionsLabel.alpha = 1
//        }
        let date = Date(timeInterval: 3, since: Date())
        let timer = Timer(fire: date, interval: 0, repeats: false) { (_) in
            UIView.animate(withDuration: 2, animations: {
                self.breathView?.transform = CGAffineTransform(scaleX: CGFloat(self.minScale), y: CGFloat(self.minScale))
                instructionsLabel.alpha = 0
            }) { (_) in
                instructionsLabel.text = "Now inhale..."
                UIView.animate(withDuration: 0.5, animations: {
                    instructionsLabel.alpha = 1
                }) { (_) in
                    self.beginMainBreathingSequence()
                    
                    let date = Date(timeInterval: 4, since: Date())
                    let nextTimer = Timer(fire: date, interval: 0, repeats: false) { (_) in
                        UIView.animate(withDuration: 0.5, animations: {
                            instructionsLabel.alpha = 0
                        }) { (_) in
                            instructionsLabel.text = "and exhale"
                            UIView.animate(withDuration: 0.5) {
                                instructionsLabel.alpha = 1
                            }
                            let date = Date(timeInterval: 5, since: Date())
                            let finalTimer = Timer(fire: date, interval: 0, repeats: false) { (_) in
                                UIView.animate(withDuration: 0.5) {
                                    instructionsLabel.alpha = 0
                                }
                            }
                            RunLoop.main.add(finalTimer, forMode: .common)
                        }
                    }
                    RunLoop.main.add(nextTimer, forMode: .common)
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}
