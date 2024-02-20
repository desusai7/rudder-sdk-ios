//
//  SourceConfigDownloadWorker.swift
//  Rudder
//
//  Created by Pallab Maiti on 18/01/24.
//  Copyright © 2024 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

protocol SourceConfigDownloadWorkerType {
    var sourceConfig: ((SourceConfig) -> Void) { get set }
}

class SourceConfigDownloadWorker: SourceConfigDownloadWorkerType {
    var sourceConfig: ((SourceConfig) -> Void) = { _ in }
    
    let sourceConfigDownloader: SourceConfigDownloaderType
    let downloadBlockers: DownloadUploadBlockersProtocol
    let userDefaults: UserDefaultsWorkerType
    let queue: DispatchQueue
    let logger: Logger
    let retryStrategy: DownloadUploadRetryStrategy
    
    @ReadWriteLock
    var readWorkItem: DispatchWorkItem?

    @ReadWriteLock
    var downloadWorkItem: DispatchWorkItem?

    init(
        sourceConfigDownloader: SourceConfigDownloaderType,
        downloadBlockers: DownloadUploadBlockersProtocol,
        userDefaults: UserDefaultsWorkerType,
        queue: DispatchQueue,
        logger: Logger,
        retryStrategy: DownloadUploadRetryStrategy
    ) {
        self.sourceConfigDownloader = sourceConfigDownloader
        self.downloadBlockers = downloadBlockers
        self.userDefaults = userDefaults
        self.queue = queue
        self.logger = logger
        self.retryStrategy = retryStrategy
        self.readWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if let sourceConfig: SourceConfig = userDefaults.read(.sourceConfig) {
                self.sourceConfig(sourceConfig)
            }
            let blockersForDownload = downloadBlockers.get()
            if blockersForDownload.isEmpty {
                self.download()
            } else {
                self.downloadNextCycle()
            }
        }
        downloadNextCycle()
    }
    
    func download() {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let response = self.sourceConfigDownloader.download()
            if let sourceConfig = response.sourceConfig {
                self.retryStrategy.reset()
                self.logger.logDebug(.sourceConfigDownloadSuccess)
                self.sourceConfig(sourceConfig)
            }
            let downloadStatus = response.status
            if downloadStatus.needsRetry {
                if self.retryStrategy.shouldRetry() {
                    self.retryStrategy.increase()
                    self.downloadNextCycle()
                    self.logger.logDebug(.retry("download source config", self.retryStrategy.current))
                } else {
                    self.logger.logDebug(.retryAborted("download source config", self.retryStrategy.retries))
                }
                return
            }
            if let error = downloadStatus.error {
                switch error {
                case .httpError(let statusCode):
                    self.logger.logError(.sourceConfigDownloadFailedWithStatusCode(statusCode))
                case .networkError(let error):
                    self.logger.logError(.sourceConfigDownloadFailedWithErrorDescription(error.localizedDescription))
                case .noResponse:
                    self.logger.logError(.noResponse)
                }
            }
        }
        self.downloadWorkItem = workItem
        queue.async(execute: workItem)
    }
    
    func downloadNextCycle() {
        guard let readWorkItem = readWorkItem else {
            return
        }
        queue.asyncAfter(deadline: .now() + retryStrategy.current, execute: readWorkItem)
    }
}
