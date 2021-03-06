/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

/// Writes data to different folders depending on the tracking consent value.
/// It synchronizes the work of underlying `FileWriters` on given read/write queue.
internal class ConsentAwareDataWriter: Writer, ConsentSubscriber {
    /// Queue used to synchronize reads and writes for the feature.
    internal let readWriteQueue: DispatchQueue
    /// Creates data processors depending on the tracking consent value.
    private let dataProcessorFactory: DataProcessorFactory
    /// Creates data migrators depending on the tracking consent transition.
    private let dataMigratorFactory: DataMigratorFactory

    /// Data processor for current tracking consent.
    private var processor: DataProcessor?

    init(
        consentProvider: ConsentProvider,
        readWriteQueue: DispatchQueue,
        dataProcessorFactory: DataProcessorFactory,
        dataMigratorFactory: DataMigratorFactory
    ) {
        self.readWriteQueue = readWriteQueue
        self.dataProcessorFactory = dataProcessorFactory
        self.dataMigratorFactory = dataMigratorFactory
        self.processor = dataProcessorFactory.resolveProcessor(for: consentProvider.currentValue)

        consentProvider.subscribe(consentSubscriber: self)

        let initialDataMigrator = dataMigratorFactory.resolveInitialMigrator()
        readWriteQueue.async { initialDataMigrator.migrate() }
    }

    // MARK: - Writer

    func write<T>(value: T) where T: Encodable {
        readWriteQueue.async {
            self.processor?.write(value: value)
        }
    }

    // MARK: - ConsentSubscriber

    func consentChanged(from oldValue: TrackingConsent, to newValue: TrackingConsent) {
        readWriteQueue.async {
            self.processor = self.dataProcessorFactory.resolveProcessor(for: newValue)
            self.dataMigratorFactory
                .resolveMigratorForConsentChange(from: oldValue, to: newValue)?
                .migrate()
        }
    }
}
