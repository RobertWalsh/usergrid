//
//  UsergridSessionDelegate.swift
//  UsergridSDK
//
//  Created by Robert Walsh on 9/30/15.
//
/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  The ASF licenses this file to You
 * under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.  For additional information regarding
 * copyright in this work, please see the NOTICE file in the top level
 * directory of this distribution.
 *
 */

import Foundation

final class UsergridSessionDelegate: NSObject {

    private var requestDelegates: [Int:UsergridAssetRequestWrapper] = [:]

    func addRequestDelegate(_ task:URLSessionTask,requestWrapper:UsergridAssetRequestWrapper) {
        requestDelegates[task.taskIdentifier] = requestWrapper
    }

    func removeRequestDelegate(_ task:URLSessionTask) {
        requestDelegates[task.taskIdentifier] = nil
    }
}

extension UsergridSessionDelegate : URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if let progressBlock = requestDelegates[task.taskIdentifier]?.progress {
            progressBlock(bytesFinished:totalBytesSent, bytesExpected: totalBytesExpectedToSend)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
        if let requestWrapper = requestDelegates[task.taskIdentifier] {
            requestWrapper.error = error
            requestWrapper.completion(requestWrapper: requestWrapper)
        }
        self.removeRequestDelegate(task)
    }
}

extension UsergridSessionDelegate : URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        if let requestWrapper = requestDelegates[dataTask.taskIdentifier] {
            requestWrapper.response = response
        }
        completionHandler(Foundation.URLSession.ResponseDisposition.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let requestWrapper = requestDelegates[dataTask.taskIdentifier] {
            var mutableData = requestWrapper.responseData != nil ? (NSMutableData(data: requestWrapper.responseData!) as Data) : Data()
            mutableData.append(data)
            requestWrapper.responseData = mutableData
        }
    }
}

extension UsergridSessionDelegate : URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let progressBlock = requestDelegates[downloadTask.taskIdentifier]?.progress {
            progressBlock(bytesFinished:totalBytesWritten, bytesExpected: totalBytesExpectedToWrite)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let requestWrapper = requestDelegates[downloadTask.taskIdentifier] {
            requestWrapper.responseData = try! Data(contentsOf: location)
        }
    }
}
