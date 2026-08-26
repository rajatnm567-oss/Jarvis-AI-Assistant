package com.jarvis.assistant

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import timber.log.Timber
import java.util.Locale

/**
 * 🎤 VOICE CONTROLLER
 * Speech-to-Text + Text-to-Speech Integration
 * Real-time voice input and Jarvis voice output
 */
class VoiceController(
    private val context: Context,
    private val onVoiceResult: (String) -> Unit,
    private val onListeningStateChanged: (Boolean) -> Unit
) : RecognitionListener, TextToSpeech.OnInitListener {

    private var speechRecognizer: SpeechRecognizer? = null
    private var textToSpeech: TextToSpeech? = null
    private var isListening = false

    init {
        initializeSpeechRecognizer()
        initializeTextToSpeech()
    }

    /**
     * 🎤 Initialize Speech Recognizer
     */
    private fun initializeSpeechRecognizer() {
        try {
            if (SpeechRecognizer.isRecognitionAvailable(context)) {
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
                speechRecognizer?.setRecognitionListener(this)
                Timber.d("✅ Speech Recognizer Initialized")
            } else {
                Timber.e("❌ Speech Recognition not available")
            }
        } catch (e: Exception) {
            Timber.e(e, "❌ Error initializing speech recognizer")
        }
    }

    /**
     * 🔊 Initialize Text-to-Speech
     */
    private fun initializeTextToSpeech() {
        try {
            textToSpeech = TextToSpeech(context, this)
            Timber.d("✅ Text-to-Speech Initialized")
        } catch (e: Exception) {
            Timber.e(e, "❌ Error initializing TTS")
        }
    }

    /**
     * Start listening for voice commands
     */
    fun startListening() {
        try {
            isListening = true
            onListeningStateChanged(true)
            Timber.d("🎤 Listening started...")

            val intent = Intent(android.speech.RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(
                    android.speech.RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                    android.speech.RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
                )
                putExtra(android.speech.RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
                putExtra(android.speech.RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                putExtra(
                    android.speech.RecognizerIntent.EXTRA_PARTIAL_RESULTS,
                    true
                )
            }

            speechRecognizer?.startListening(intent)

        } catch (e: Exception) {
            Timber.e(e, "❌ Error starting listening")
            isListening = false
            onListeningStateChanged(false)
        }
    }

    /**
     * Stop listening
     */
    fun stopListening() {
        try {
            speechRecognizer?.stopListening()
            isListening = false
            onListeningStateChanged(false)
            Timber.d("🛑 Listening stopped")
        } catch (e: Exception) {
            Timber.e(e, "❌ Error stopping listening")
        }
    }

    /**
     * 🗣️ Speak using Text-to-Speech
     */
    suspend fun speak(text: String) = withContext(Dispatchers.Main) {
        try {
            Timber.d("🗣️ Speaking: $text")
            textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null)
        } catch (e: Exception) {
            Timber.e(e, "❌ Error speaking")
        }
    }

    /**
     * Set voice parameters
     */
    fun setVoiceParameters(
        pitch: Float = 1.0f,
        speed: Float = 1.0f
    ) {
        textToSpeech?.apply {
            this.pitch = pitch
            this.setSpeechRate(speed)
            Timber.d("🎛️ Voice parameters set - Pitch: $pitch, Speed: $speed")
        }
    }

    /**
     * Is currently listening
     */
    fun isListeningNow(): Boolean = isListening

    /**
     * Speech Recognizer Callbacks
     */

    override fun onReadyForSpeech(params: Bundle?) {
        Timber.d("🎤 Ready for speech")
    }

    override fun onBeginningOfSpeech() {
        Timber.d("🎤 Speech begun")
    }

    override fun onRmsChanged(rmsdB: Float) {
        // Volume level changes
    }

    override fun onBufferReceived(buffer: ByteArray?) {
        Timber.d("📦 Buffer received")
    }

    override fun onEndOfSpeech() {
        Timber.d("🎤 Speech ended")
    }

    override fun onError(error: Int) {
        isListening = false
        onListeningStateChanged(false)
        val errorMessage = when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio error"
            SpeechRecognizer.ERROR_CLIENT -> "Client error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NO_MATCH -> "No match found"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
            else -> "Unknown error"
        }
        Timber.e("❌ Recognition Error: $errorMessage")
    }

    override fun onResults(results: Bundle?) {
        isListening = false
        onListeningStateChanged(false)

        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (!matches.isNullOrEmpty()) {
            val recognizedText = matches[0]
            Timber.d("✅ Recognized: $recognizedText")
            onVoiceResult(recognizedText)
        }
    }

    override fun onPartialResults(partialResults: Bundle?) {
        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (!matches.isNullOrEmpty()) {
            Timber.d("📝 Partial: ${matches[0]}")
        }
    }

    override fun onEvent(eventType: Int, params: Bundle?) {
        Timber.d("🎤 Event: $eventType")
    }

    /**
     * TextToSpeech Initialization Callback
     */
    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            textToSpeech?.language = Locale.getDefault()
            Timber.d("✅ TTS Engine Ready")
        } else {
            Timber.e("❌ TTS Engine failed to initialize")
        }
    }

    /**
     * Cleanup resources
     */
    fun release() {
        try {
            speechRecognizer?.destroy()
            textToSpeech?.shutdown()
            Timber.d("🗑️ Voice Controller released")
        } catch (e: Exception) {
            Timber.e(e, "❌ Error releasing resources")
        }
    }
}
