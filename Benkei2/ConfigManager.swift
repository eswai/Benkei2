import Foundation

class ConfigManager {
    static let shared = ConfigManager()
    
    private let configDirectory: URL
    private let naginataFileName = "Naginata.yaml"

    private init() {
        // ~/Library/Application Support/Benkei2/config ディレクトリのパスを設定
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        configDirectory = appSupport
            .appendingPathComponent("Benkei2")
            .appendingPathComponent("config")
    }
    
    /// 設定ディレクトリの初期化（初回起動時）
    func initializeConfigDirectory() {
        let fileManager = FileManager.default

        // 設定ディレクトリが存在するかチェック
        if !fileManager.fileExists(atPath: configDirectory.path) {
            print("Config directory not found. Creating: \(configDirectory.path)")
            
            do {
                // ディレクトリを作成
                try fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true, attributes: nil)
                print("Config directory created successfully")
                
                // アプリバンドルから設定ファイルをコピー
                copyDefaultConfigFiles()
            } catch {
                print("Failed to create config directory: \(error)")
            }
        } else {
            print("Config directory already exists: \(configDirectory.path)")
        }
    }
    
    /// アプリバンドルから設定ファイルを設定ディレクトリにコピー
    private func copyDefaultConfigFiles() {
        let fileManager = FileManager.default
        
        // Naginata.yaml をコピー
        if let bundleNaginataPath = Bundle.main.path(forResource: "Naginata", ofType: "yaml") {
            let configNaginataURL = configDirectory.appendingPathComponent(naginataFileName)
            
            do {
                try fileManager.copyItem(atPath: bundleNaginataPath, toPath: configNaginataURL.path)
                print("Copied Naginata.yaml to config directory")
            } catch {
                print("Failed to copy Naginata.yaml: \(error)")
            }
        }
    }
    
    /// Naginata.yaml のパスを取得（設定ディレクトリから）
    func getNaginataConfigPath() -> String? {
        let configPath = configDirectory.appendingPathComponent(naginataFileName).path
        
        if FileManager.default.fileExists(atPath: configPath) {
            return configPath
        } else {
            print("Naginata.yaml not found in config directory")
            // フォールバック：アプリバンドルから読み込み
            return Bundle.main.path(forResource: "Naginata", ofType: "yaml")
        }
    }
    
    /// 設定ディレクトリのパスを取得（ユーザー用）
    func getConfigDirectoryPath() -> String {
        return configDirectory.path
    }
}
