import Foundation

struct FileEvent {
    let kind: Kind
    let file: URL
    let mtime: Date

    enum Kind {
        case created
        case modified
        case deleted
    }
}

extension URL {
    func eventStream(pollingMs: UInt) -> AsyncStream<FileEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: FileEvent.self)

        let task = Task {
            defer { continuation.finish() }

            guard var mtimesKnown = enumerateFilesMtime(at: self) else {
                return
            }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: Duration.milliseconds(pollingMs))
                } catch {
                    break
                }

                guard let mtimesSeen = enumerateFilesMtime(at: self) else {
                    continue
                }

                let known = Set(mtimesKnown.keys)
                let seen = Set(mtimesSeen.keys)

                // created
                for file in seen.subtracting(known) {
                    continuation.yield(
                        FileEvent(kind: .created, file: file, mtime: mtimesSeen[file]!))
                }

                // modified
                for file in known.intersection(seen) {
                    if let last = mtimesSeen[file], last != mtimesKnown[file] {
                        continuation.yield(FileEvent(kind: .modified, file: file, mtime: last))
                    }
                }

                // deleted
                for file in known.subtracting(seen) {
                    // NOTE mtime is an approximation
                    continuation.yield(FileEvent(kind: .deleted, file: file, mtime: Date.now))
                }

                mtimesKnown = mtimesSeen
            }
        }

        continuation.onTermination = { _ in
            task.cancel()
        }

        return stream
    }
}

private func enumerateFilesMtime(at: URL) -> [URL: Date]? {
    let keys: Set<URLResourceKey> = [
        .isRegularFileKey,
        .contentModificationDateKey,
    ]

    var failed = false

    guard
        let enumerator = FileManager.default.enumerator(
            at: at,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles],
            errorHandler: { (url, error) in
                print("Failed to access \(url): \(error.localizedDescription)")
                failed = true
                return false
            }
        )
    else {
        return nil
    }

    var mtimes = [URL: Date]()

    for case let file as URL in enumerator {
        if Task.isCancelled { return nil }

        let values: URLResourceValues
        do {
            values = try file.resourceValues(forKeys: keys)
        } catch {
            return nil
        }

        guard values.isRegularFile == true else {
            continue
        }

        guard let mtime = values.contentModificationDate else {
            return nil
        }

        mtimes[file] = mtime
    }

    return failed ? nil : mtimes
}
