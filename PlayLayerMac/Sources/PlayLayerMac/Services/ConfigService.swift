import Foundation

struct ConfigService {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func load() -> AppConfig {
        let url = configURL()

        guard
            let data = try? Data(contentsOf: url),
            let config = try? decoder.decode(AppConfig.self, from: data)
        else {
            return .default
        }

        return config
    }

    func save(_ config: AppConfig) {
        let url = configURL()
        let directory = url.deletingLastPathComponent()

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        guard let data = try? encoder.encode(config) else {
            return
        }

        try? data.write(to: url, options: .atomic)
    }

    private func configURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("PlayLayer", isDirectory: true)
            .appendingPathComponent("config.json", isDirectory: false)
    }
}
