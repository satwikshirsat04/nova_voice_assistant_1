package com.example.nova_voice_assistant

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val STT_CHANNEL = "nova/stt"
    private val LLM_CHANNEL = "nova/llm"
    private val TTS_CHANNEL = "nova/tts"
    private val MODEL_CHANNEL = "nova/model"
    
    private lateinit var sttNative: ParakeetNative
    private lateinit var llmNative: LFM2Native
    private lateinit var ttsNative: KokoroNative
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize native handlers
        sttNative = ParakeetNative(context)
        llmNative = LFM2Native(context)
        ttsNative = KokoroNative(context)
        
        // STT Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath != null) {
                        try {
                            val success = sttNative.loadModel(modelPath)
                            result.success(success)
                        } catch (e: Exception) {
                            result.error("LOAD_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "modelPath is required", null)
                    }
                }
                "transcribe" -> {
                    val audioData = call.argument<ByteArray>("audioData")
                    if (audioData != null) {
                        try {
                            val transcript = sttNative.transcribe(audioData)
                            result.success(transcript)
                        } catch (e: Exception) {
                            result.error("TRANSCRIBE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "audioData is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // LLM Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LLM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    val contextSize = call.argument<Int>("contextSize") ?: 2048
                    val threads = call.argument<Int>("threads") ?: 4
                    
                    if (modelPath != null) {
                        try {
                            val success = llmNative.loadModel(modelPath, contextSize, threads)
                            result.success(success)
                        } catch (e: Exception) {
                            result.error("LOAD_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "modelPath is required", null)
                    }
                }
                "generate" -> {
                    val prompt = call.argument<String>("prompt")
                    val maxTokens = call.argument<Int>("maxTokens") ?: 256
                    val temperature = call.argument<Double>("temperature") ?: 0.7
                    val topP = call.argument<Double>("topP") ?: 0.9
                    
                    if (prompt != null) {
                        try {
                            val response = llmNative.generate(
                                prompt, 
                                maxTokens, 
                                temperature.toFloat(), 
                                topP.toFloat()
                            )
                            result.success(response)
                        } catch (e: Exception) {
                            result.error("GENERATE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "prompt is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // TTS Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TTS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath != null) {
                        try {
                            val success = ttsNative.loadModel(modelPath)
                            result.success(success)
                        } catch (e: Exception) {
                            result.error("LOAD_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "modelPath is required", null)
                    }
                }
                "synthesize" -> {
                    val text = call.argument<String>("text")
                    val speed = call.argument<Double>("speed") ?: 1.0
                    val voice = call.argument<String>("voice") ?: "female"
                    
                    if (text != null) {
                        try {
                            val audioData = ttsNative.synthesize(text, speed.toFloat(), voice)
                            result.success(audioData)
                        } catch (e: Exception) {
                            result.error("SYNTHESIZE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "text is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // Model Management Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MODEL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getModelInfo" -> {
                    val info = mapOf(
                        "sttLoaded" to sttNative.isLoaded(),
                        "llmLoaded" to llmNative.isLoaded(),
                        "ttsLoaded" to ttsNative.isLoaded()
                    )
                    result.success(info)
                }
                "unloadAll" -> {
                    try {
                        sttNative.unload()
                        llmNative.unload()
                        ttsNative.unload()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("UNLOAD_ERROR", e.message, null)
                    }
                }
                "isLoaded" -> {
                    val modelType = call.argument<String>("modelType")
                    val loaded = when (modelType) {
                        "stt" -> sttNative.isLoaded()
                        "llm" -> llmNative.isLoaded()
                        "tts" -> ttsNative.isLoaded()
                        else -> false
                    }
                    result.success(loaded)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onDestroy() {
        // Clean up native resources
        sttNative.unload()
        llmNative.unload()
        ttsNative.unload()
        super.onDestroy()
    }
}