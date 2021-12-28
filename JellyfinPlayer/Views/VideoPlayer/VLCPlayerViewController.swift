//
//  PlayerViewController.swift
//  JellyfinVideoPlayerDev
//
//  Created by Ethan Pippin on 11/12/21.
//

import AVKit
import AVFoundation
import Combine
import JellyfinAPI
import MediaPlayer
import MobileVLCKit
import SwiftUI
import UIKit

class VLCPlayerViewController: UIViewController {
    
    // MARK: variables
    
    private let viewModel: VideoPlayerViewModel
    private var vlcMediaPlayer = VLCMediaPlayer()
    private var lastPlayerTicks: Int64
    private var cancellables = Set<AnyCancellable>()
    private var overlayDismissTimer: Timer?
    
    private var currentPlayerTicks: Int64 {
        return Int64(vlcMediaPlayer.time.intValue) * 100_000
    }
    
    private var displayingOverlay: Bool {
        return overlayHostingController.view.alpha > 0
    }
    
    private lazy var videoContentView = makeVideoContentView()
    private lazy var tapGestureView = makeTapGestureView()
    private lazy var overlayHostingController = makeOverlayHostingController()
    
    // MARK: init
    
    init(viewModel: VideoPlayerViewModel) {
        
        self.viewModel = viewModel
        
        self.lastPlayerTicks = viewModel.item.userData?.playbackPositionTicks ?? 0
        
        super.init(nibName: nil, bundle: nil)
        
        viewModel.playerOverlayDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        view.addSubview(videoContentView)
        view.addSubview(tapGestureView)
        
        addChild(overlayHostingController)
        overlayHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        overlayHostingController.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        view.addSubview(overlayHostingController.view)
        overlayHostingController.didMove(toParent: self)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            videoContentView.topAnchor.constraint(equalTo: view.topAnchor),
            videoContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoContentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoContentView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        NSLayoutConstraint.activate([
            tapGestureView.topAnchor.constraint(equalTo: videoContentView.topAnchor),
            tapGestureView.bottomAnchor.constraint(equalTo: videoContentView.bottomAnchor),
            tapGestureView.leftAnchor.constraint(equalTo: videoContentView.leftAnchor),
            tapGestureView.rightAnchor.constraint(equalTo: videoContentView.rightAnchor)
        ])
        NSLayoutConstraint.activate([
            overlayHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            overlayHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayHostingController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            overlayHostingController.view.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    // MARK: viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        AppUtility.lockOrientation(.all, andRotateTo: .landscapeLeft)
    }
    
    // MARK: viewWillDisappear
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        AppUtility.lockOrientation(.all)
    }
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviews()
        setupConstraints()
        
        setupViewModelListeners()
        
        view.backgroundColor = .black
        
        setupMediaPlayer()
    }
    
    // MARK: setupViewModelListeners
    
    private func setupViewModelListeners() {
        viewModel.$playbackSpeed.sink { newSpeed in
            self.vlcMediaPlayer.rate = Float(newSpeed.rawValue)
        }.store(in: &cancellables)
        
        viewModel.$screenFilled.sink { shouldFill in
            self.changeFill(to: shouldFill)
        }.store(in: &cancellables)
        
        viewModel.$sliderIsScrubbing.sink { sliderIsScrubbing in
            if !sliderIsScrubbing {
                self.didEndScrubbing(position: self.viewModel.sliderPercentage)
            }
        }.store(in: &cancellables)
        
        viewModel.$selectedAudioStreamIndex.sink { newAudioStreamIndex in
            self.didSelectAudioStream(index: newAudioStreamIndex)
        }.store(in: &cancellables)
        
        viewModel.$selectedSubtitleStreamIndex.sink { newSubtitleStreamIndex in
            self.didSelectSubtitleStream(index: newSubtitleStreamIndex)
        }.store(in: &cancellables)
    }
    
    private func changeFill(to shouldFill: Bool) {
        if shouldFill {
            // TODO: May not be possible with current VLCKit
            
//            let drawableView = vlcMediaPlayer.drawable as! UIView
//            let drawableViewSize = drawableView.frame.size
//            let mediaSize = vlcMediaPlayer.videoSize
            
            // Largest size from mediaSize is how it is currently filled
            //     in the drawable view, find scaleFactor by filling entire
            //     drawableView
            
            vlcMediaPlayer.scaleFactor = 1.5
        } else {
            vlcMediaPlayer.scaleFactor = 0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startPlayback()
        restartOverlayDismissTimer()
    }
    
    // MARK: subviews
    
    private func makeVideoContentView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        
        return view
    }
    
    private func makeTapGestureView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didRightSwipe))
        rightSwipeGesture.direction = .right
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didLeftSwipe))
        leftSwipeGesture.direction = .left
        
        view.addGestureRecognizer(singleTapGesture)
        view.addGestureRecognizer(rightSwipeGesture)
        view.addGestureRecognizer(leftSwipeGesture)
        
        return view
    }
    
    @objc private func didTap() {
        self.didGenerallyTap()
    }
    
    @objc private func didRightSwipe() {
        self.didSelectForward()
    }
    
    @objc private func didLeftSwipe() {
        self.didSelectBackward()
    }
    
    private func makeOverlayHostingController() -> UIHostingController<VLCPlayerCompactOverlayView> {
        let overlayView = VLCPlayerCompactOverlayView(viewModel: viewModel)
        return UIHostingController(rootView: overlayView)
    }
}

// MARK: setupMediaPlayer
extension VLCPlayerViewController {
    
    func setupMediaPlayer() {
        
        vlcMediaPlayer.delegate = self
        vlcMediaPlayer.drawable = videoContentView
        vlcMediaPlayer.perform(Selector(("setTextRendererFontSize:")), with: 14)

        let media = VLCMedia(url: viewModel.streamURL)
        media.addOption("--prefetch-buffer-size=1048576")
        media.addOption("--network-caching=5000")
        
        vlcMediaPlayer.media = media
    }
    
    func startPlayback() {
        vlcMediaPlayer.play()
        
        viewModel.sendPlayReport(startTimeTicks: viewModel.item.userData?.playbackPositionTicks ?? 0)
        
        // 1 second = 10,000,000 ticks
        let startTicks: Int64 = viewModel.item.userData?.playbackPositionTicks ?? 0

        if startTicks != 0 {
            let videoPosition = Double(vlcMediaPlayer.time.intValue / 1000)
            let secondsScrubbedTo = startTicks / 10_000_000
            let offset = secondsScrubbedTo - Int64(videoPosition)
            if offset > 0 {
                vlcMediaPlayer.jumpForward(Int32(offset))
            } else {
                vlcMediaPlayer.jumpBackward(Int32(abs(offset)))
            }
        }
    }
}

// MARK: Show/Hide Overlay
extension VLCPlayerViewController {
    
    private func showOverlay() {
        guard overlayHostingController.view.alpha != 1 else { return }
        
        UIView.animate(withDuration: 0.2) {
            self.overlayHostingController.view.alpha = 1
        }
    }
    
    private func hideOverlay() {
        guard overlayHostingController.view.alpha != 0 else { return }
        
        UIView.animate(withDuration: 0.2) {
            self.overlayHostingController.view.alpha = 0
        }
    }
    
    private func toggleOverlay() {
        if overlayHostingController.view.alpha < 1 {
            showOverlay()
        } else {
            hideOverlay()
        }
    }
}

// MARK: OverlayTimer
extension VLCPlayerViewController {
    
    private func restartOverlayDismissTimer(interval: Double = 2) {
        self.overlayDismissTimer?.invalidate()
        self.overlayDismissTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(dismissTimerFired), userInfo: nil, repeats: false)
    }
    
    @objc private func dismissTimerFired() {
        print("Dismiss timer fired")
        self.hideOverlay()
    }
    
    private func stopOverlayDismissTimer() {
        self.overlayDismissTimer?.invalidate()
    }
}

// MARK: VLCMediaPlayerDelegate
extension VLCPlayerViewController: VLCMediaPlayerDelegate {
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        
        self.viewModel.playerState = vlcMediaPlayer.state
        
        print("Player state changed: \(viewModel.playerState.rawValue)")
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        
        guard !viewModel.sliderIsScrubbing else {
            lastPlayerTicks = currentPlayerTicks
            return
        }
        
        viewModel.sliderPercentage = Double(vlcMediaPlayer.position)
        
        if abs(currentPlayerTicks - lastPlayerTicks) >= 10000 {
            
            viewModel.playerState = VLCMediaPlayerState.playing
        }
        
        lastPlayerTicks = currentPlayerTicks

//        if CACurrentMediaTime() - lastProgressReportTime > 5 {
//            mediaPlayer.currentVideoSubTitleIndex = selectedCaptionTrack
//            sendProgressReport(eventName: "timeupdate")
//            lastProgressReportTime = CACurrentMediaTime()
//        }
    }
}

// MARK: PlayerOverlayDelegate
extension VLCPlayerViewController: PlayerOverlayDelegate {
    
    func didSelectAudioStream(index: Int) {
        vlcMediaPlayer.currentAudioTrackIndex = Int32(index)
        print("New audio index: \(index)")
    }
    
    func didSelectSubtitleStream(index: Int) {
        vlcMediaPlayer.currentVideoSubTitleIndex = Int32(index)
        
        if index != -1 {
            // set in case weren't shown
            viewModel.captionsEnabled = true
        } 
        print("New subtitle index: \(index)")
    }
    
    func didSelectClose() {
        vlcMediaPlayer.stop()
        
        viewModel.sendStopReport(ticks: currentPlayerTicks)
        
        dismiss(animated: true, completion: nil)
    }
    
    func didSelectGoogleCast() {
        print("didSelectCast")
    }
    
    func didSelectAirplay() {
        print("didSelectAirplay")
    }
    
    func didSelectCaptions() {
        
        viewModel.captionsEnabled = !viewModel.captionsEnabled
        
        if viewModel.captionsEnabled {
            vlcMediaPlayer.currentVideoSubTitleIndex = vlcMediaPlayer.videoSubTitlesIndexes[1] as! Int32
        } else {
            vlcMediaPlayer.currentVideoSubTitleIndex = -1
        }
    }
    
    // TODO: Implement properly in overlays
    func didSelectMenu() {
        stopOverlayDismissTimer()
    }
    
    // TODO: Implement properly in overlays
    func didDeselectMenu() {
        restartOverlayDismissTimer()
    }
    
    func didSelectBackward() {
        vlcMediaPlayer.jumpBackward(10)
        
        restartOverlayDismissTimer()
    }
    
    func didSelectForward() {
        vlcMediaPlayer.jumpForward(10)
        
        restartOverlayDismissTimer()
    }
    
    func didSelectMain() {
        
        switch viewModel.playerState {
        case .stopped: ()
        case .opening: ()
        case .buffering:
            vlcMediaPlayer.play()
            restartOverlayDismissTimer()
        case .ended: ()
        case .error: ()
        case .playing:
            vlcMediaPlayer.pause()
            restartOverlayDismissTimer(interval: 5)
        case .paused:
            vlcMediaPlayer.play()
        case .esAdded: ()

        default: ()
        }
    }
    
    func didGenerallyTap() {
        toggleOverlay()
        
        restartOverlayDismissTimer(interval: 5)
    }
    
    func didBeginScrubbing() {
        
    }
    
    func didEndScrubbing(position: Double) {
        let videoPosition = Double(vlcMediaPlayer.time.intValue / 1000)
        let videoDuration = Double(viewModel.item.runTimeTicks! / 10_000_000)
        let secondsScrubbedTo = round(viewModel.sliderPercentage * videoDuration)
        let newPositionOffset = secondsScrubbedTo - videoPosition
        
        if newPositionOffset > 0 {
            vlcMediaPlayer.jumpForward(Int32(newPositionOffset))
        } else {
            vlcMediaPlayer.jumpBackward(Int32(abs(newPositionOffset)))
        }
        
        print("Scrubbed position: \(position)")
    }
}
