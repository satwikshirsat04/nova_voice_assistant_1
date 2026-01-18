package com.example.nova_voice_assistant

import android.content.Context
import java.io.File

/**
 * Native wrapper for LFM-2 LLM using llama.cpp
 * Handles text generation with GGUF quantized models
 */
class LFM2Native(private val context: Context) {
    
    private var isModelLoaded = false
    private var modelPath: String? = null
    private var contextSize: Int = 2048
    private var nThreads: Int = 4
    
    // Native methods (implemented in C++ via JNI)
    private external fun nativeLoadModel(
        modelPath: String,
        contextSize: Int,
        nThreads: Int
    ): Boolean
    
    private external fun nativeGenerate(
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        topP: Float
    ): String
    
    private external fun nativeUnload()
    
    private external fun nativeIsLoaded(): Boolean
    
    companion object {
        init {
            try {
                // Load llama.cpp native library
                System.loadLibrary("llama-android")
            } catch (e: UnsatisfiedLinkError) {
                e.printStackTrace()
            }
        }
    }
    
    /**
     * Load LFM-2 GGUF model
     */
    fun loadModel(
        modelPath: String,
        contextSize: Int = 2048,
        nThreads: Int = 4
    ): Boolean {
        if (isModelLoaded) {
            return true
        }
        
        try {
            val modelFile = File(modelPath)
            if (!modelFile.exists()) {
                throw IllegalArgumentException("Model file not found: $modelPath")
            }
            
            this.modelPath = modelPath
            this.contextSize = contextSize
            this.nThreads = nThreads
            
            val success = nativeLoadModel(modelPath, contextSize, nThreads)
            
            if (success) {
                isModelLoaded = true
            }
            
            return success
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * Generate text response from prompt
     */
    fun generate(
        prompt: String,
        maxTokens: Int = 256,
        temperature: Float = 0.7f,
        topP: Float = 0.9f
    ): String {
        if (!isModelLoaded) {
            throw IllegalStateException("Model not loaded")
        }
        
        try {
            // Sanitize inputs
            val sanitizedPrompt = sanitizePrompt(prompt)
            val clampedMaxTokens = maxTokens.coerceIn(1, 1024)
            val clampedTemperature = temperature.coerceIn(0f, 2f)
            val clampedTopP = topP.coerceIn(0f, 1f)
            
            // Call native generation
            val response = nativeGenerate(
                sanitizedPrompt,
                clampedMaxTokens,
                clampedTemperature,
                clampedTopP
            )
            
            return response.trim()
        } catch (e: Exception) {
            e.printStackTrace()
            throw RuntimeException("Text generation failed: ${e.message}")
        }
    }
    
    /**
     * Sanitize prompt text
     */
    private fun sanitizePrompt(prompt: String): String {
        // Remove any potentially problematic characters
        return prompt
            .replace("\u0000", "")  // Null characters
            .trim()
    }
    
    /**
     * Build prompt with conversation context
     * This matches the format expected by LFM-2
     */
    fun buildPrompt(
        systemPrompt: String,
        conversationHistory: List<Pair<String, String>>,
        currentUserInput: String
    ): String {
        val builder = StringBuilder()
        
        // System prompt
        builder.append("<|system|>\n")
        builder.append(systemPrompt)
        builder.append("\n<|end|>\n")
        
        // Conversation history
        for ((userMsg, assistantMsg) in conversationHistory) {
            builder.append("<|user|>\n")
            builder.append(userMsg)
            builder.append("\n<|end|>\n")
            
            builder.append("<|assistant|>\n")
            builder.append(assistantMsg)
            builder.append("\n<|end|>\n")
        }
        
        // Current user input
        builder.append("<|user|>\n")
        builder.append(currentUserInput)
        builder.append("\n<|end|>\n")
        
        // Assistant prompt
        builder.append("<|assistant|>")
        
        return builder.toString()
    }
    
    /**
     * Unload model and free resources
     */
    fun unload() {
        if (isModelLoaded) {
            try {
                nativeUnload()
                isModelLoaded = false
                modelPath = null
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    /**
     * Check if model is loaded
     */
    fun isLoaded(): Boolean {
        return isModelLoaded && nativeIsLoaded()
    }
    
    /**
     * Get model information
     */
    fun getModelInfo(): Map<String, Any> {
        return mapOf(
            "loaded" to isModelLoaded,
            "modelPath" to (modelPath ?: ""),
            "contextSize" to contextSize,
            "threads" to nThreads
        )
    }
}

/**
 * NOTE: The native C++ implementation would look like this:
 * 
 * // File: android/app/src/main/cpp/llama_android.cpp
 * 
 * #include <jni.h>
 * #include "llama.h"
 * 
 * static llama_context* g_ctx = nullptr;
 * static llama_model* g_model = nullptr;
 * 
 * extern "C" JNIEXPORT jboolean JNICALL
 * Java_com_example_nova_1voice_1assistant_LFM2Native_nativeLoadModel(
 *     JNIEnv* env,
 *     jobject thiz,
 *     jstring model_path,
 *     jint context_size,
 *     jint n_threads
 * ) {
 *     const char* path = env->GetStringUTFChars(model_path, nullptr);
 *     
 *     llama_backend_init(false);
 *     
 *     llama_model_params model_params = llama_model_default_params();
 *     g_model = llama_load_model_from_file(path, model_params);
 *     
 *     if (!g_model) {
 *         env->ReleaseStringUTFChars(model_path, path);
 *         return JNI_FALSE;
 *     }
 *     
 *     llama_context_params ctx_params = llama_context_default_params();
 *     ctx_params.n_ctx = context_size;
 *     ctx_params.n_threads = n_threads;
 *     
 *     g_ctx = llama_new_context_with_model(g_model, ctx_params);
 *     
 *     env->ReleaseStringUTFChars(model_path, path);
 *     return g_ctx != nullptr ? JNI_TRUE : JNI_FALSE;
 * }
 * 
 * // Additional native methods for generate, unload, etc.
 */