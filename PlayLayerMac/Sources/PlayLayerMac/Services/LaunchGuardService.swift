import Foundation

final class LaunchGuardService {
    private var socketDescriptor: Int32 = -1
    private var socketURL: URL?
    private(set) var lastFailureReason: String?

    func acquire() -> Bool {
        lastFailureReason = nil
        let socketURL = socketFileURL()
        self.socketURL = socketURL

        guard createSocketDescriptor() else {
            lastFailureReason = "socket() failed"
            return false
        }

        if bindSocket(at: socketURL) {
            listen(socketDescriptor, 1)
            return true
        }

        if existingInstanceIsAlive(at: socketURL) {
            lastFailureReason = "existing instance responded on launch socket"
            close(socketDescriptor)
            socketDescriptor = -1
            return false
        }

        unlink(socketURL.path)
        close(socketDescriptor)
        socketDescriptor = -1

        guard createSocketDescriptor() else {
            lastFailureReason = "socket() retry failed after stale socket cleanup"
            return false
        }

        if bindSocket(at: socketURL) {
            listen(socketDescriptor, 1)
            return true
        }

        lastFailureReason = "bind() retry failed after stale socket cleanup"
        close(socketDescriptor)
        socketDescriptor = -1
        return false
    }

    deinit {
        if socketDescriptor != -1 {
            close(socketDescriptor)
        }

        if let socketURL {
            unlink(socketURL.path)
        }
    }

    private func bindSocket(at url: URL) -> Bool {
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)

        let maxLength = MemoryLayout.size(ofValue: address.sun_path)
        let utf8Path = url.path.utf8CString
        guard utf8Path.count < maxLength else {
            return false
        }

        withUnsafeMutablePointer(to: &address.sun_path) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: maxLength) { rebounded in
                rebounded.initialize(repeating: 0, count: maxLength)
                for (index, byte) in utf8Path.enumerated() {
                    rebounded[index] = byte
                }
            }
        }

        let addressLength = socklen_t(MemoryLayout<sa_family_t>.size + utf8Path.count)
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                bind(socketDescriptor, sockaddrPointer, addressLength)
            }
        }

        return result == 0
    }

    private func createSocketDescriptor() -> Bool {
        socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        return socketDescriptor != -1
    }

    private func existingInstanceIsAlive(at url: URL) -> Bool {
        let probeSocket = socket(AF_UNIX, SOCK_STREAM, 0)
        if probeSocket == -1 {
            return false
        }
        defer { close(probeSocket) }

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)

        let maxLength = MemoryLayout.size(ofValue: address.sun_path)
        let utf8Path = url.path.utf8CString
        guard utf8Path.count < maxLength else {
            return false
        }

        withUnsafeMutablePointer(to: &address.sun_path) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: maxLength) { rebounded in
                rebounded.initialize(repeating: 0, count: maxLength)
                for (index, byte) in utf8Path.enumerated() {
                    rebounded[index] = byte
                }
            }
        }

        let addressLength = socklen_t(MemoryLayout<sa_family_t>.size + utf8Path.count)
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                connect(probeSocket, sockaddrPointer, addressLength)
            }
        }

        return result == 0
    }

    private func socketFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("PlayLayer", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("playlayer.sock", isDirectory: false)
    }
}
