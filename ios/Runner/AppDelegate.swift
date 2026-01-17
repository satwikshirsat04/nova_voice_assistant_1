import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var sttNative: ParakeetNative?
    private var llmNative: LFM2Native?
    private var ttsNative: KokoroNative?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        
        // Initialize native handlers
        sttNative = ParakeetNative()
        llmNative = LFM2Native()
        ttsNative = KokoroNative()
        
        // STT Channel
        let sttChannel = FlutterMethodChannel(
            name: "nova/stt",
            binaryMessenger: controller.binaryMessenger
        )
        
        sttChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "loadModel":
                if let args = call.arguments as? [String: Any],
                   let modelPath = args["modelPath"] as? String {
                    let success = self.sttNative?.loadModel(modelPath: modelPath) ?? false
                    result(success)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "modelPath is required", details: nil))
                }
                
            case "transcribe":
                if let args = call.arguments as? [String: Any],
                   let audioData = args["audioData"] as? FlutterStandardTypedData {
                    do {
                        let transcript = try self.sttNative?.transcribe(audioData: audioData.data) ?? ""
                        result(transcript)
                    } catch {
                        result(FlutterError(code: "TRANSCRIBE_ERROR", message: error.localizedDescription, details: nil))
                    }
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "audioData is required", details: nil))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // LLM Channel
        let llmChannel = FlutterMethodChannel(
            name: "nova/llm",
            binaryMessenger: controller.binaryMessenger
        )
        
        llmChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "loadModel":
                if let args = call.arguments as? [String: Any],
                   let modelPath = args["modelPath"] as? String {
                    let contextSize = args["contextSize"] as? Int ?? 2048
                    let threads = args["threads"] as? Int ?? 4
                    
                    let success = self.llmNative?.loadModel(
                        modelPath: modelPath,
                        contextSize: contextSize,
                        threads: threads
                    ) ?? false
                    result(success)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "modelPath is required", details: nil))
                }
                
            case "generate":
                if let args = call.arguments as? [String: Any],
                   let prompt = args["prompt"] as? String {
                    let maxTokens = args["maxTokens"] as? Int ?? 256
                    let temperature = args["temperature"] as? Double ?? 0.7
                    let topP = args["topP"] as? Double ?? 0.9
                    
                    do {
                        let response = try self.llmNative?.generate(
                            prompt: prompt,
                            maxTokens: maxTokens,
                            temperature: Float(temperature),
                            topP: Float(topP)
                        ) ?? ""
                        result(response)
                    } catch {
                        result(FlutterError(code: "GENERATE_ERROR", message: error.localizedDescription, details: nil))
                    }
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "prompt is required", details: nil))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // TTS Channel
        let ttsChannel = FlutterMethodChannel(
            name: "nova/tts",
            binaryMessenger: controller.binaryMessenger
        )
        
        ttsChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "loadModel":
                if let args = call.arguments as? [String: Any],
                   let modelPath = args["modelPath"] as? String {
                    let success = self.ttsNative?.loadModel(modelPath: modelPath) ?? false
                    result(success)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "modelPath is required", details: nil))
                }
                
            case "synthesize":
                if let args = call.arguments as? [String: Any],
                   let text = args["text"] as? String {
                    let speed = args["speed"] as? Double ?? 1.0
                    let voice = args["voice"] as? String ?? "female"
                    
                    do {
                        let audioData = try self.ttsNative?.synthesize(
                            text: text,
                            speed: Float(speed),
                            voice: voice
                        ) ?? Data()
                        result(FlutterStandardTypedData(bytes: audioData))
                    } catch {
                        result(FlutterError(code: "SYNTHESIZE_ERROR", message: error.localizedDescription, details: nil))
                    }
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "text is required", details: nil))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Model Management Channel
        let modelChannel = FlutterMethodChannel(
            name: "nova/model",
            binaryMessenger: controller.binaryMessenger
        )
        
        modelChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "getModelInfo":
                let info: [String: Bool] = [
                    "sttLoaded": self.sttNative?.isLoaded() ?? false,
                    "llmLoaded": self.llmNative?.isLoaded() ?? false,
                    "ttsLoaded": self.ttsNative?.isLoaded() ?? false
                ]
                result(info)
                
            case "unloadAll":
                self.sttNative?.unload()
                self.llmNative?.unload()
                self.ttsNative?.unload()
                result(nil)
                
            case "isLoaded":
                if let args = call.arguments as? [String: Any],
                   let modelType = args["modelType"] as? String {
                    let loaded: Bool
                    switch modelType {
                    case "stt":
                        loaded = self.sttNative?.isLoaded() ?? false
                    case "llm":
                        loaded = self.llmNative?.isLoaded() ?? false
                    case "tts":
                        loaded = self.ttsNative?.isLoaded() ?? false
                    default:
                        loaded = false
                    }
                    result(loaded)
                } else {
                    result(false)
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        // Clean up native resources
        sttNative?.unload()
        llmNative?.unload()
        ttsNative?.unload()
        super.applicationWillTerminate(application)
    }
}