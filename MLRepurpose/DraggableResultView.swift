//
//  DraggableResultView.swift
//  MLRepurpose
//
//  Created by Jackson Ho on 1/7/20.
//  Copyright © 2020 Jackson Ho. All rights reserved.
//

import UIKit
import CoreData

class DraggableResultView: UIView, UIGestureRecognizerDelegate {
        
    var timeStampView = UIView()
    var timeStampTitle = UILabel()
    private var grayBar = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        timeStampView = createTimeStampView()
        timeStampTitle = createTimeStampTitle()
        grayBar = createGrayBar()
        addSubview(timeStampView)
        timeStampView.addSubview(timeStampTitle)
        timeStampView.addSubview(grayBar)
        grayBarConstraints()
    }
    
    private func createTimeStampView() -> UIView {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        view.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/1.2, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        view.layer.cornerRadius = 25
        view.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.layer.borderWidth = 0.5
        view.layer.borderColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        return view
    }
    
    private func createTimeStampTitle() -> UILabel {
        // Edit this with the label cells
        let label = UILabel()
        label.text = "Finished work sessions"
        label.textAlignment = .left
        label.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.8)
        label.font = UIFont(name: "Avenir-Heavy", size: 25)
        return label
    }

    private func createGrayBar() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
        view.layer.cornerRadius = 3
        return view
    }

    
    func viewDragged(gesture: UIPanGestureRecognizer) {
        configViewFrame(gesture: gesture)
        snapView(gesture: gesture)
        configViewBrightness()
    }

    private func configViewFrame(gesture: UIPanGestureRecognizer) {
        let buffer: CGFloat = 135
        let recognizer = gesture
        let translation = recognizer.translation(in: self)
        var frame = timeStampView.frame
        let viewHeight = timeStampView.frame.origin.y + translation.y
        if viewHeight > buffer {
            frame.origin.y = viewHeight
            timeStampView.frame = frame
            recognizer.setTranslation(CGPoint(x: 0, y: 0), in: self)
        } else if viewHeight == buffer {
            timeStampView.frame = frame
        }
    }

    private func configViewBrightness() {
        if timeStampView.frame.origin.y < timeStampView.frame.height / 2 {
            UIView.animate(withDuration: 0.25, animations: {
                self.backgroundColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1)
            })
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.backgroundColor = UIColor.white
            })
        }
    }

    private func snapView(gesture: UIPanGestureRecognizer) {
        if gesture.state == UIPanGestureRecognizer.State.ended {
            let velocity = gesture.velocity(in: self)
            if velocity.y > 0 {
                UIView.animate(withDuration: 0.5, animations: {
                    self.timeStampView.frame.origin.y = self.timeStampView.frame.height / 1.25
                })
            } else {
                if timeStampView.frame.origin.y < timeStampView.frame.height / 2.25 {
                    UIView.animate(withDuration: 0.5, animations: {
                        self.timeStampView.frame.origin.y = self.timeStampView.frame.height / 5
                    })
                } else if timeStampView.frame.origin.y <= timeStampView.frame.height / 1.3 &&
                    timeStampView.frame.origin.y > timeStampView.frame.height / 2.25 {
                    UIView.animate(withDuration: 0.5, animations: {
                        self.timeStampView.frame.origin.y = self.timeStampView.frame.height / 2
                    })
                } else {
                    UIView.animate(withDuration: 0.5, animations: {
                        self.timeStampView.frame.origin.y = self.timeStampView.frame.height / 1.25
                    })
                }
            }
        }
    }
    
    private func timeStampTitleConstraints() {
        timeStampTitle.translatesAutoresizingMaskIntoConstraints = false
        timeStampTitle.widthAnchor.constraint(equalTo: timeStampView.widthAnchor, multiplier: 0.8).isActive = true
        timeStampTitle.heightAnchor.constraint(equalToConstant: 50).isActive = true
        timeStampTitle.topAnchor.constraint(equalToSystemSpacingBelow: timeStampView.topAnchor, multiplier: 2).isActive = true
        timeStampTitle.leftAnchor.constraint(equalToSystemSpacingAfter: timeStampView.leftAnchor, multiplier: 2).isActive = true
    }

    private func grayBarConstraints() {
        grayBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grayBar.widthAnchor.constraint(equalTo: timeStampView.widthAnchor, multiplier: 0.15),
            grayBar.heightAnchor.constraint(equalToConstant: 6),
            grayBar.centerXAnchor.constraint(equalTo: timeStampView.centerXAnchor),
            grayBar.topAnchor.constraint(equalToSystemSpacingBelow: timeStampView.topAnchor, multiplier: 1.5)
        ])
    }
}
