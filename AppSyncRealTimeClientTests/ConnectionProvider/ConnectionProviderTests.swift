//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AppSyncRealTimeClient

class ConnectionProviderTests: RealtimeConnectionProviderTestBase {

    /// Provider test
    ///
    /// Given:
    /// - A configured subscriber -> provider -> websocket chain
    /// When:
    /// - I invoke `provider.connect()`
    /// - And the websocket properly connects
    /// Then:
    /// - The subscriber is notified of the successful connection
    func testSuccessfulConnection() {
        receivedNotConnected.isInverted = true
        receivedError.isInverted = true

        let onConnect: MockWebsocketProvider.OnConnect = { _, _, delegate in
            self.websocketDelegate = delegate
            DispatchQueue.global().async {
                delegate?.websocketDidConnect(provider: self.websocket)
            }
        }

        let onDisconnect: MockWebsocketProvider.OnDisconnect = { }

        let onWrite: MockWebsocketProvider.OnWrite = { message in
            guard RealtimeConnectionProviderTestBase.messageType(of: message, equals: "connection_init") else {
                XCTFail("Incoming message did not have 'connection_init' type")
                return
            }

            self.websocketDelegate.websocketDidReceiveData(
                provider: self.websocket,
                data: RealtimeConnectionProviderTestBase.makeConnectionAckMessage()
            )
        }

        websocket = MockWebsocketProvider(
            onConnect: onConnect,
            onDisconnect: onDisconnect,
            onWrite: onWrite
        )

        // Retain the provider so it doesn't release prior to executing callbacks
        let provider = createProviderAndConnect()

        // Get rid of "written to, but never read" compiler warnings
        print(provider)

        waitForExpectations(timeout: 0.05)
    }

    /// Provider test
    ///
    /// Given:
    /// - A configured subscriber -> provider -> websocket chain
    /// When:
    /// - I invoke `provider.connect()`
    /// - And the websocket reports a connection error
    /// Then:
    /// - The subscriber is notified of the unsuccessful connection
    func testConnectionError() {
        receivedConnected.isInverted = true
        receivedNotConnected.isInverted = true

        let onConnect: MockWebsocketProvider.OnConnect = { _, _, delegate in
            self.websocketDelegate = delegate
            DispatchQueue.global().async {
                delegate?.websocketDidConnect(provider: self.websocket)
            }
        }

        let onDisconnect: MockWebsocketProvider.OnDisconnect = { }

        let onWrite: MockWebsocketProvider.OnWrite = { message in
            guard RealtimeConnectionProviderTestBase.messageType(of: message, equals: "connection_init") else {
                XCTFail("Incoming message did not have 'connection_init' type")
                return
            }

            self.websocketDelegate.websocketDidDisconnect(
                provider: self.websocket,
                error: "test error"
            )
        }

        websocket = MockWebsocketProvider(
            onConnect: onConnect,
            onDisconnect: onDisconnect,
            onWrite: onWrite
        )

        // Retain the provider so it doesn't release prior to executing callbacks
        let provider = createProviderAndConnect()

        // Get rid of "written to, but never read" compiler warnings
        print(provider)

        waitForExpectations(timeout: 0.05)
    }

    /// Stale connection test
    ///
    /// Given:
    /// - A provider configured with a default stale connection timeout
    /// When:
    /// - The service sends a message containing an override timeout value
    /// Then:
    /// - The provider updates its stale connection timeout to the service-provided value
    func testServiceOverridesStaleConnectionTimeout() {
        receivedNotConnected.isInverted = true
        receivedError.isInverted = true

        let expectedTimeoutInSeconds = 60.0
        let timeoutInMilliseconds = Int(expectedTimeoutInSeconds) * 1_000

        let onConnect: MockWebsocketProvider.OnConnect = { _, _, delegate in
            self.websocketDelegate = delegate
            DispatchQueue.global().async {
                delegate?.websocketDidConnect(provider: self.websocket)
            }
        }

        let onDisconnect: MockWebsocketProvider.OnDisconnect = { }

        let connectionAckMessage = RealtimeConnectionProviderTestBase
            .makeConnectionAckMessage(withTimeout: timeoutInMilliseconds)
        let onWrite: MockWebsocketProvider.OnWrite = { message in
            guard RealtimeConnectionProviderTestBase.messageType(of: message, equals: "connection_init") else {
                XCTFail("Incoming message did not have 'connection_init' type")
                return
            }

            self.websocketDelegate.websocketDidReceiveData(
                provider: self.websocket,
                data: connectionAckMessage
            )
        }

        websocket = MockWebsocketProvider(
            onConnect: onConnect,
            onDisconnect: onDisconnect,
            onWrite: onWrite
        )

        let provider = createProviderAndConnect()

        wait(for: [receivedConnected], timeout: 0.05)
        XCTAssertEqual(provider.staleConnectionTimeout.get(), expectedTimeoutInSeconds)

        waitForExpectations(timeout: 0.05)
    }

}
