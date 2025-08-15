import Foundation

class ConfigManager {
    static let shared = ConfigManager()
    
    private let configDirectory: URL
    private let naginataFileName = "Naginata.yaml"
    private let abcFileName = "ABC.yaml"
    
    private init() {
        // ~/Library/Containers/jp.eswai.Benkei2/Data/config ディレクトリのパスを設定
        configDirectory = FileManager.default.homeDirectoryForCurrentUser
             .appendingPathComponent("config")
    }
    
    /// 設定ディレクトリの初期化（初回起動時）
    func initializeConfigDirectory() {
        let fileManager = FileManager.default
        
        // ~/Library/Containers/jp.eswai.Benkei2/Data/configディレクトリが存在するかチェック
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
    
    /// アプリバンドルから設定ファイルを ~/Library/Containers/jp.eswai.Benkei2/Data/configにコピー
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
        
        // ABC.yaml をコピー
        if let bundleABCPath = Bundle.main.path(forResource: "ABC", ofType: "yaml") {
            let configABCURL = configDirectory.appendingPathComponent(abcFileName)
            
            do {
                try fileManager.copyItem(atPath: bundleABCPath, toPath: configABCURL.path)
                print("Copied ABC.yaml to config directory")
            } catch {
                print("Failed to copy ABC.yaml: \(error)")
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
    
    /// ABC.yaml のパスを取得（設定ディレクトリから）
    func getABCConfigPath() -> String? {
        let configPath = configDirectory.appendingPathComponent(abcFileName).path
        
        if FileManager.default.fileExists(atPath: configPath) {
            return configPath
        } else {
            print("ABC.yaml not found in config directory")
            // フォールバック：アプリバンドルから読み込み
            return Bundle.main.path(forResource: "ABC", ofType: "yaml")
        }
    }
    
    /// 設定ディレクトリのパスを取得（ユーザー用）
    func getConfigDirectoryPath() -> String {
        return configDirectory.path
    }
}
