/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

/// Crash Report format supported by Datadog SDK.
@objc
public class DDCrashReport: NSObject {
    /// The date of the crash occurrence.
    internal let crashDate: Date?
    // TODO: RUMM-1053 - consider providing / formatting this characteristic of the crash report
    internal let signalCode: String?
    // TODO: RUMM-1053 - consider providing / formatting this characteristic of the crash report
    internal let signalName: String?
    // TODO: RUMM-1053 - consider providing / formatting this characteristic of the crash report
    internal let signalDetails: String?
    // TODO: RUMM-1053 - consider providing / formatting this characteristic of the crash report
    internal let stackTrace: String?
    /// The last context injected through `inject(context:)`
    internal let context: Data?

    public init(
        crashDate: Date?,
        signalCode: String?,
        signalName: String?,
        signalDetails: String?,
        stackTrace: String?,
        context: Data?
    ) {
        self.crashDate = crashDate
        self.signalCode = signalCode
        self.signalName = signalName
        self.signalDetails = signalDetails
        self.stackTrace = stackTrace
        self.context = context
    }
}

/// An interface for enabling crash reporting feature in Datadog SDK.
/// It is implemented by `DDCrashReportingPlugin` from `DatadogCrashReporting` framework.
///
/// The SDK calls each API on a background thread and succeeding calls are synchronized.
@objc
public protocol DDCrashReportingPluginType: class {
    /// Reads unprocessed crash report if available.
    /// - Parameter completion: the completion block called with the value of `DDCrashReport` if a crash report is available
    /// or with `nil` otherwise. The value returned by the receiver should indicate if the crash report was processed correctly (`true`)
    /// or something went wrong (`false)`. Depending on the returned value, the crash report will be purged or perserved for future read.
    ///
    /// The SDK calls this method on a background thread. The implementation is free to choice any thread
    /// for executing the  `completion`.
    func readPendingCrashReport(completion: (DDCrashReport?) -> Bool)

    /// Injects custom data for describing the application state in the crash report.
    /// This data will be attached to produced crash report and will be available in `DDCrashReport`.
    ///
    /// The SDK calls this method for each significant application state change.
    /// It is called on a background thread and succeeding calls are synchronized.
    func inject(context: Data)
}