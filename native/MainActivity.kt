package com.lingora.academy

import android.os.Bundle
import android.content.Intent
import android.media.MediaPlayer
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import java.util.Locale
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var audio: MediaPlayer? = null
    private var tts: TextToSpeech? = null
    private var ready = false
    private var recognition: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        tts = TextToSpeech(this) { status -> ready = status == TextToSpeech.SUCCESS }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val preferences = getSharedPreferences("lingora", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.lingora.academy/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadProgress" -> result.success(preferences.getString("progress", null))
                    "saveProgress" -> {
                        if (preferences.edit().putString("progress", call.arguments as String).commit()) {
                            result.success(null)
                        } else result.error("storage", "Could not save progress.", null)
                    }
                    "speak" -> {
                        val engine = tts
                        val language = Locale.forLanguageTag(call.argument<String>("language") ?: "en-US")
                        if (!ready || engine == null || engine.setLanguage(language) < 0) {
                            result.error("tts", "Install a compatible voice in Android settings.", null)
                        } else {
                            audio?.release()
                            audio = null
                            engine.setSpeechRate((call.argument<Double>("speed") ?: 1.0).toFloat())
                            val status = engine.speak(call.argument<String>("text") ?: "", TextToSpeech.QUEUE_FLUSH, null, "lingora")
                            if (status == TextToSpeech.SUCCESS) result.success(null)
                            else result.error("tts", "Android could not play this phrase.", null)
                        }
                    }
                    "playAsset" -> {
                        val path = call.argument<String>("asset") ?: ""
                        if (!Regex("assets/audio/w[1-5]l[1-3]_[0-2]\\.mp3").matches(path)) {
                            result.error("audio", "Invalid audio file.", null)
                        } else {
                            tts?.stop()
                            audio?.release()
                            audio = null
                            val player = MediaPlayer()
                            try {
                                val key = io.flutter.FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(path)
                                assets.openFd(key).use { file ->
                                    player.setDataSource(file.fileDescriptor, file.startOffset, file.length)
                                }
                                player.prepare()
                                audio = player
                                player.start()
                                result.success(null)
                            } catch (_: Exception) {
                                player.release()
                                audio = null
                                result.error("audio", "Practice audio could not be played.", null)
                            }
                        }
                    }
                    "stopSpeech" -> {
                        tts?.stop()
                        audio?.release()
                        audio = null
                        result.success(null)
                    }
                    "recognize" -> {
                        if (recognition != null) {
                            result.error("busy", "Speech recognition is already open.", null)
                        } else {
                            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
                                .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                .putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-US")
                                .putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
                                .putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                            try {
                                recognition = result
                                startActivityForResult(intent, 91)
                            } catch (_: android.content.ActivityNotFoundException) {
                                recognition = null
                                result.error("stt", "Android speech recognition is unavailable.", null)
                            } catch (_: SecurityException) {
                                recognition = null
                                result.error("stt", "Microphone access is unavailable.", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Android activity result callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 91) {
            recognition?.success(if (resultCode == RESULT_OK) {
                data?.getStringArrayListExtra(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                    ?: data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
            } else null)
            recognition = null
        }
    }

    override fun onDestroy() {
        tts?.stop()
        tts?.shutdown()
        audio?.release()
        super.onDestroy()
    }
}
