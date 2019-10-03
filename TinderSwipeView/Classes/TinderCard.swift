//
//  TinderCard.swift
//  TinderSwipeView
//
//  Created by Nick on 11/05/19.
//  Copyright © 2019 Nick. All rights reserved.
//

import UIKit

let theresoldMargin = (UIScreen.main.bounds.size.width/2) * 0.75
let stength : CGFloat = 4
let range : CGFloat = 0.90

protocol TinderCardDelegate: NSObjectProtocol {
    func didSelectCard(card: TinderCard)
    func cardGoesRight(card: TinderCard)
    func cardGoesLeft(card: TinderCard)
    func currentCardStatus(card: TinderCard, distance: CGFloat)
    func fallbackCard(card: TinderCard)
}

class TinderCard: UIView {

    var overlayImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.alpha = 0
        return imageView
    }()
    
    var index: Int!
    
    var roundedOverlay: UIView?
    var overlay: UIView?
    var containerView : UIView!
    weak var delegate: TinderCardDelegate?
    
    var xCenter: CGFloat = 0.0
    var yCenter: CGFloat = 0.0
    var originalPoint = CGPoint.zero
    var cornerRadius: CGFloat = 5 {
        didSet {
            roundedOverlay?.layer.cornerRadius = cornerRadius
            roundedOverlay?.layoutIfNeeded()
            layer.shadowPath =
            UIBezierPath(roundedRect: bounds,
                         cornerRadius: roundedOverlay?.layer.cornerRadius ?? 0).cgPath
        }
    }
    var isLiked = false
    var model : Any?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     * Initializing View
     */
    func setupView() {
        
        if roundedOverlay == nil {
            roundedOverlay = UIView(frame: bounds)
            roundedOverlay?.backgroundColor = .white
            roundedOverlay?.layer.cornerRadius = cornerRadius
            roundedOverlay?.clipsToBounds = true
            insertSubview(roundedOverlay ?? UIView(), at: 0)
        } else {
            roundedOverlay?.frame = frame
        }
        
        layer.shadowPath =
        UIBezierPath(roundedRect: bounds,
                     cornerRadius: roundedOverlay?.layer.cornerRadius ?? 0).cgPath
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.35
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
        clipsToBounds = false
        
        backgroundColor = .clear
        originalPoint = center
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.beingDragged))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        
        containerView = UIView(frame: bounds)
        containerView.backgroundColor = .clear
        
        overlayImageView = UIImageView(frame:bounds)
        containerView.addSubview(overlayImageView)
    }
    
    /*
     * Adding Overlay to TinderCard
     */
    func addContentView( view: UIView?) {
        
        if let overlay = view {
            self.overlay = overlay
            overlay.backgroundColor = .brown
            
            roundedOverlay?.insertSubview(overlay, belowSubview: containerView)
        }
    }
    
    /*
     * Card goes right method
     */
    func cardGoesRight() {
        
        delegate?.cardGoesRight(card: self)
        let finishPoint = CGPoint(x: frame.size.width*2, y: 2 * yCenter + originalPoint.y)
        UIView.animate(withDuration: 0.5, animations: {
            self.center = finishPoint
        }, completion: {(_) in
            self.removeFromSuperview()
        })
        isLiked = true
    }
    
    /*
     * Card goes left method
     */
    func cardGoesLeft() {
        
        delegate?.cardGoesLeft(card: self)
        let finishPoint = CGPoint(x: -frame.size.width*2, y: 2 * yCenter + originalPoint.y)
        UIView.animate(withDuration: 0.5, animations: {
            self.center = finishPoint
        }, completion: {(_) in
            self.removeFromSuperview()
        })
        isLiked = false
    }
    
    /*
     * Card goes right action method
     */
    func rightClickAction() {
        
        setInitialLayoutStatus(isleft: false)
        let finishPoint = CGPoint(x: center.x + frame.size.width * 2, y: center.y)
        UIView.animate(withDuration: 1.0, animations: {() -> Void in
            self.animateCard(to: finishPoint, angle: 1, alpha: 1.0)
        }, completion: {(_ complete: Bool) -> Void in
            self.removeFromSuperview()
        })
        isLiked = true
        delegate?.cardGoesRight(card: self)
    }
    
    
    /*
     * Card goes left action method
     */
    func leftClickAction() {
        
        setInitialLayoutStatus(isleft: true)
        let finishPoint = CGPoint(x: center.x - frame.size.width * 2, y: center.y)
        UIView.animate(withDuration: 1.0, animations: {() -> Void in
            self.animateCard(to: finishPoint, angle: -1, alpha: 1.0)
        }, completion: {(_ complete: Bool) -> Void in
            self.removeFromSuperview()
        })
        isLiked = false
        delegate?.cardGoesLeft(card: self)
    }
    
    /*
     * Reverting current card method
     */
    func makeUndoAction() {
        
        overlayImageView.image = makeImage(name: isLiked ? "overlay_like" : "overlay_skip")
        overlayImageView.alpha = 1.0
        UIView.animate(withDuration: 0.4, animations: {() -> Void in
            self.center = self.originalPoint
            self.transform = CGAffineTransform(rotationAngle: 0)
            self.overlayImageView.alpha = 0
        })
    }
    
    /*
     * Removing last card from view
     */
    func rollBackCard(){
        
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 0
        }) { (_) in
            self.removeFromSuperview()
        }
    }
    
    /*
     * Shake animation method
     */
    func shakeAnimationCard(completion: @escaping (Bool) -> ()){
        
        overlayImageView.image = makeImage(name: "overlay_skip")
        UIView.animate(withDuration: 0.5, animations: {() -> Void in
            let finishPoint = CGPoint(x: self.center.x - (self.frame.size.width / 2), y: self.center.y)
            self.animateCard(to: finishPoint, angle: -0.2, alpha: 1.0)
        }, completion: {(_) -> Void in
            UIView.animate(withDuration: 0.5, animations: {() -> Void in
                self.animateCard(to: self.originalPoint)
            }, completion: {(_ complete: Bool) -> Void in
                self.overlayImageView.image =  self.makeImage(name: "overlay_like")
                UIView.animate(withDuration: 0.5, animations: {() -> Void in
                    let finishPoint = CGPoint(x: self.center.x + (self.frame.size.width / 2) ,y: self.center.y)
                    self.animateCard(to: finishPoint , angle: 0.2, alpha: 1)
                }, completion: {(_ complete: Bool) -> Void in
                    UIView.animate(withDuration: 0.5, animations: {() -> Void in
                        self.animateCard(to: self.originalPoint)
                    }, completion: {(_ complete: Bool) -> Void in
                        completion(true)
                    })
                })
            })
        })
    }
    
    /*
     * Setting up initial status for imageviews
     */
    fileprivate func setInitialLayoutStatus(isleft:Bool){
        
        overlayImageView.alpha = 0.5
        
        overlayImageView.image = makeImage(name: isleft ?  "overlay_skip" : "overlay_like")
    }
    
    /*
     * Acessing image from bundle
     */
    fileprivate func makeImage(name: String) -> UIImage? {
        
        let image = UIImage(named: name, in: Bundle(for: type(of: self)), compatibleWith: nil)
        return image
    }
    
    /*
     * Animation with center point
     */
    fileprivate func animateCard(to center:CGPoint,angle:CGFloat = 0,alpha:CGFloat = 0){
        
        self.center = center
        self.transform = CGAffineTransform(rotationAngle: angle)
        overlayImageView.alpha = alpha
    }
}

// MARK: UIGestureRecognizerDelegate Methods
extension TinderCard: UIGestureRecognizerDelegate {
    
    /*
     * Gesture methods
     */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /*
     * Gesture methods
     */
    @objc fileprivate func beingDragged(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        xCenter = gestureRecognizer.translation(in: self).x
        yCenter = gestureRecognizer.translation(in: self).y
        switch gestureRecognizer.state {
        // Keep swiping
        case .began:
            originalPoint = self.center;
            roundedOverlay?.addSubview(containerView)
            self.delegate?.didSelectCard(card: self)
            break;
        //in the middle of a swipe
        case .changed:
            let rotationStrength = min(xCenter / UIScreen.main.bounds.size.width, 1)
            let rotationAngel = .pi/8 * rotationStrength
            let scale = max(1 - abs(rotationStrength) / stength, range)
            center = CGPoint(x: originalPoint.x + xCenter, y: originalPoint.y + yCenter)
            let transforms = CGAffineTransform(rotationAngle: rotationAngel)
            let scaleTransform: CGAffineTransform = transforms.scaledBy(x: scale, y: scale)
            self.transform = scaleTransform
            updateOverlay(xCenter)
            break;
            
        // swipe ended
        case .ended:
            containerView.removeFromSuperview()
            afterSwipeAction()
            break;
            
        case .possible:break
        case .cancelled:break
        case .failed:break
        @unknown default:
            fatalError()
        }
    }
    
    /*
     * Tinder Card swipe action
     */
    fileprivate func afterSwipeAction() {
        
        if xCenter > theresoldMargin {
            cardGoesRight()
        }
        else if xCenter < -theresoldMargin {
            cardGoesLeft()
        }
        else {
            self.delegate?.fallbackCard(card: self)
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: [], animations: {
                self.center = self.originalPoint
                self.transform = CGAffineTransform(rotationAngle: 0)
                self.overlayImageView.alpha = 0
            })
        }
    }
    
    /*
     * Updating overlay methods
     */
    fileprivate func updateOverlay(_ distance: CGFloat) {
        overlayImageView.image = makeImage(name:  distance > 0 ? "overlay_like" : "overlay_skip")
        overlayImageView.alpha = min(abs(distance) / 100, 0.8)
        delegate?.currentCardStatus(card: self, distance: distance)
    }
}
