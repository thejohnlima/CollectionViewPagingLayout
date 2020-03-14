//
//  SnapshotTransformView.swift
//  CollectionViewPagingLayout
//
//  Created by Amir on 07/03/2020.
//  Copyright © 2020 Amir Khorsandi. All rights reserved.
//

import UIKit

public protocol SnapshotTransformView: TransformableView {
    
    /// Options for controlling the effects, see `SnapshotTransformViewOptions.swift`
    var options: SnapshotTransformViewOptions { get }
    
    /// The view to apply the effect on
    var targetView: UIView { get }
    
    /// The identifier for snapshot, it won't make a new snapshot if
    /// there is a cashed snapshot with the same identifier
    var identifier: String { get }
    
    /// If you wish to extend this protocol and add more transformations to it
    /// you can implement this method and do whatever you want
    func extendTransform(snapshot: SnapshotContainerView, progress: CGFloat)
}


public extension SnapshotTransformView {
    
    /// An empty default implementation for extendTransform to make it optional
    func extendTransform(snapshot: SnapshotContainerView, progress: CGFloat) {}
    
}


public extension SnapshotTransformView where Self: UICollectionViewCell {
    
    /// Default `targetView` for `UICollectionViewCell` is the first subview of
    /// `contentView` or the content view itself in case of no subviews
    var targetView: UIView {
        contentView.subviews.first ?? contentView
    }
    
    /// Default `identifier` for `UICollectionViewCell` is it's index
    /// if you have the same content with different indexes (like infinite list)
    /// you should override this and provide a content-based identifier
    var identifier: String {
        var collectionView: UICollectionView? = nil
        var superview = self.superview
        while superview != nil {
            if let view = superview as? UICollectionView {
                collectionView = view
                break
            }
            superview = superview?.superview
        }
        return "\(collectionView?.indexPath(for: self) ?? IndexPath())"
    }
}


public extension SnapshotTransformView {
    
    // MARK: Properties
    
    var options: SnapshotTransformViewOptions {
        .init()
    }
    
    // MARK: TransformableView
    
    func transform(progress: CGFloat) {
        targetView.layer.cornerRadius = 30
        guard let snapshot = findSnapshot() ?? makeSnapshot() else {
            return
        }
        if progress == 0 {
            targetView.transform = .identity
            snapshot.alpha = 0
        } else {
            snapshot.alpha = 1
            // hide the original view, we apply transform on the snapshot
            targetView.transform = CGAffineTransform.identity.translatedBy(x: 0, y: -UIScreen.main.bounds.height)
        }
        snapshot.transform(progress: progress, options: options)
        
        extendTransform(snapshot: snapshot, progress: progress)
    }
    
    // MARK: Private functions
    
    private func findSnapshot() -> SnapshotContainerView? {
        let snapshot = targetView.superview?.subviews.first(where: { $0 is SnapshotContainerView }) as? SnapshotContainerView
        if let snapshot = snapshot, (snapshot.identifier != identifier || snapshot.snapshotSize != targetView.bounds.size) {
            snapshot.removeFromSuperview()
            return nil
        }
        return snapshot
    }
    
    private func makeSnapshot() -> SnapshotContainerView? {
        guard let view = SnapshotContainerView(targetView: targetView, pieceSizeRatio: options.pieceSizeRatio, identifier: identifier) else {
            return nil
        }
        targetView.superview?.insertSubview(view, aboveSubview: targetView)
        targetView.equalSize(to: view)
        targetView.center(to: view)
        return view
    }
    
}


private extension SnapshotContainerView {
    
    //    func transform(progress: CGFloat) {
    //        let scale = 1 - abs(progress) * 0.2
    //        transform = CGAffineTransform.identity.translatedBy(x: progress * frame.width * 1.3, y: 0).scaledBy(x: scale, y: scale)
    //        let pieceScale = 1 - abs(progress) * 1
    //        snapshots.forEach {
    //            $0.transform = CGAffineTransform.identity.scaledBy(x: pieceScale, y: pieceScale)
    //            $0.layer.cornerRadius = abs(progress) * min($0.frame.height, $0.frame.width)
    //            $0.layer.masksToBounds = true
    //        }
    //    }
    
    
    func transform(progress: CGFloat, options: SnapshotTransformViewOptions) {
        let scale = 1 - abs(progress) * options.containerScaleRatio
        transform = CGAffineTransform.identity
            .translatedBy(x: progress * frame.width * options.containerTranslationRatio.x,
                          y: progress * frame.height * options.containerTranslationRatio.y)
            .scaledBy(x: scale, y: scale)
        
        let pieceScale = 1 - abs(progress) * options.pieceScaleRatio
        snapshots.enumerated().forEach { index, view in
            let column = Int(index % Int(1.0 / options.pieceSizeRatio.width))
            let row = Int((index + 1) / Int(1.0 / options.pieceSizeRatio.width))
            var factor: CGFloat = 0
            if column > 2 { factor = 1 }
            if column < 2 { factor = -1 }
            if column < 1 { factor = -2 }
            if column > 3 { factor = 2 }
            view.transform = CGAffineTransform.identity.translatedBy(x: 70 * abs(progress) * factor, y: 0).scaledBy(x: pieceScale, y: pieceScale)
            view.layer.cornerRadius = abs(progress) * min(view.frame.height, view.frame.width)
            view.layer.masksToBounds = true
        }
    }
}



public struct SnapshotTransformViewOptions {
    
    /// Ratio for computing the size of each piece in the snapshot
    /// width = view.width * `pieceSizeRatio.width`
    var pieceSizeRatio: CGSize = .init(width: 1.0/5.0, height: 1.0/8.0)
    
    /// Ratio for computing scale of each piece in the snapshot
    /// Scale = 1 - abs(progress) * `pieceScaleRatio`
    var pieceScaleRatio: CGFloat = 1
    
    /// Ratio for computing scale for the snapshot container
    /// Scale = 1 - abs(progress) * `scaleRatio`
    var containerScaleRatio: CGFloat = 0.25
    
    /// Ratio for the amount of translate for container view, calculates by `targetView` size
    /// for instance, if containerTranslationRatio.x = 0.5 and targetView.width = 100 then
    /// translateX = 50 for the right view and translateX = -50 for the left view
    var containerTranslationRatio: CGPoint = .init(x: 1.8, y: 0)
    
    var piecesRowTranslationRatio: CGPoint = .init(x: 1.8, y: 0)
    
    var piecesColumnTranslationRatio: CGPoint = .init(x: 1.8, y: 0)
}


public enum piecesOption {
    case rowColumn(CGFloat, CGFloat)
    case custom([CGFloat])
    case oddEven(CGFloat, CGFloat)
}