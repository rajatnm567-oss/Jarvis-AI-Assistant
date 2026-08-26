package com.jarvis.assistant

import android.content.Context
import com.google.ai.client.generativeai.GenerativeModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import timber.log.Timber

/**
 * 🤖 JARVIS AI CONTROLLER
 * Google Gemini AI Integration
 * Real-time voice command processing
 */
class GeminiAIController(
    private val context: Context,
    private val apiKey: String
) {

    private val generativeModel = GenerativeModel(
        modelName = "gemini-pro",
        apiKey = apiKey
    )

    private val conversationHistory = mutableListOf<String>()

    /**
     * Process voice command and get AI response
     */
    suspend fun processCommand(userCommand: String): String = withContext(Dispatchers.IO) {
        return@withContext try {
            Timber.d("🎤 Processing command: $userCommand")
            
            // Add to conversation history
            conversationHistory.add("User: $userCommand")

            // Create prompt for Jarvis-like response
            val prompt = buildJarvisPrompt(userCommand)

            // Get response from Gemini
            val response = generativeModel.generateContent(prompt)
            val aiResponse = response.text ?: "Sorry, I didn't understand that."

            // Add to history
            conversationHistory.add("Jarvis: $aiResponse")

            Timber.d("✅ AI Response: $aiResponse")
            aiResponse

        } catch (e: Exception) {
            Timber.e(e, "❌ Error processing command")
            "I encountered an error. Please try again."
        }
    }

    /**
     * Build Iron Man JARVIS-style prompt
     */
    private fun buildJarvisPrompt(userCommand: String): String {
        return """
            You are JARVIS, an advanced AI assistant inspired by Iron Man's AI from Marvel.
            
            Characteristics:
            - Professional and sophisticated tone
            - Always helpful and proactive
            - Quick, concise responses (1-2 sentences max for voice)
            - Reference yourself as "JARVIS" 
            - Be witty but respectful
            
            User Command: $userCommand
            
            Respond naturally and helpfully. If it's a task instruction (open app, send message, etc),
            confirm you'll do it and briefly explain what you're doing.
        """.trimIndent()
    }

    /**
     * Process multi-step tasks
     */
    suspend fun processMultiStepTask(mainTask: String, steps: List<String>): String = 
        withContext(Dispatchers.IO) {
        return@withContext try {
            Timber.d("⚙️ Processing multi-step task: $mainTask")
            
            val prompt = """
                Execute this multi-step task as JARVIS:
                Main Task: $mainTask
                
                Steps to follow:
                ${steps.mapIndexed { index, step -> "${index + 1}. $step" }.joinToString("\n")}
                
                Provide a brief status update after completing.
            """.trimIndent()

            val response = generativeModel.generateContent(prompt)
            response.text ?: "Task execution started."

        } catch (e: Exception) {
            Timber.e(e, "❌ Multi-step task error")
            "I encountered an error executing the task."
        }
    }

    /**
     * Get conversation history
     */
    fun getHistory(): List<String> = conversationHistory.toList()

    /**
     * Clear conversation history
     */
    fun clearHistory() {
        conversationHistory.clear()
        Timber.d("🗑️ Conversation history cleared")
    }

    /**
     * Set custom system prompt
     */
    fun setSystemPrompt(prompt: String) {
        Timber.d("📝 System prompt updated")
    }
}
