package com.itschool.mathbuddies

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val storageChannelName = "mathbuddies/storage"
    private val mediaChannelName = "mathbuddies/media"

    private var soundPool: SoundPool? = null
    private val soundIds = HashMap<String, Int>()
    private var musicPlayer: MediaPlayer? = null
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    private val soundNames = listOf(
        "pop", "click", "sparkle", "correct", "wrong",
        "star", "win", "jump", "place", "whoosh", "flip", "chest"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initAudio()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            storageChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "load" -> result.success(loadProgress())
                "save" -> {
                    val payload = call.argument<String>("data") ?: ""
                    result.success(saveProgress(payload))
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            mediaChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    playSound(call.argument<String>("name") ?: "")
                    result.success(true)
                }
                "musicOn" -> {
                    startMusic()
                    result.success(true)
                }
                "musicOff" -> {
                    stopMusic()
                    result.success(true)
                }
                "speak" -> {
                    speak(call.argument<String>("text") ?: "")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ---------------- audio ----------------

    private fun initAudio() {
        try {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            soundPool = SoundPool.Builder()
                .setMaxStreams(6)
                .setAudioAttributes(attrs)
                .build()
            for (name in soundNames) {
                val resId = resources.getIdentifier(name, "raw", packageName)
                if (resId != 0) {
                    soundPool?.let { pool -> soundIds[name] = pool.load(this, resId, 1) }
                }
            }
        } catch (e: Exception) {
            // No sound effects -> app still works.
        }
        try {
            tts = TextToSpeech(this) { status ->
                ttsReady = status == TextToSpeech.SUCCESS
                if (ttsReady) {
                    tts?.setPitch(1.15f)
                    tts?.setSpeechRate(0.95f)
                }
            }
        } catch (e: Exception) {
            // No TTS engine -> app still works silently.
        }
    }

    private fun playSound(name: String) {
        try {
            val pool = soundPool ?: return
            val id = soundIds[name] ?: return
            pool.play(id, 1.0f, 1.0f, 1, 0, 1.0f)
        } catch (e: Exception) {
            // ignore
        }
    }

    private fun startMusic() {
        try {
            if (musicPlayer == null) {
                val resId = resources.getIdentifier("music_loop", "raw", packageName)
                if (resId == 0) return
                musicPlayer = MediaPlayer.create(this, resId)
                musicPlayer?.isLooping = true
                musicPlayer?.setVolume(0.22f, 0.22f)
            }
            if (musicPlayer?.isPlaying == false) {
                musicPlayer?.start()
            }
        } catch (e: Exception) {
            // ignore
        }
    }

    private fun stopMusic() {
        try {
            musicPlayer?.pause()
        } catch (e: Exception) {
            // ignore
        }
    }

    private fun speak(text: String) {
        try {
            if (ttsReady && text.isNotEmpty()) {
                tts?.speak(
                    text,
                    TextToSpeech.QUEUE_FLUSH,
                    null,
                    "mb_" + System.currentTimeMillis()
                )
            }
        } catch (e: Exception) {
            // ignore
        }
    }

    // ---------------- storage ----------------

    private fun progressFile(): File =
        File(applicationContext.filesDir, "mathbuddies_progress.json")

    private fun loadProgress(): String =
        try {
            if (progressFile().exists()) progressFile().readText() else ""
        } catch (e: Exception) {
            ""
        }

    private fun saveProgress(payload: String): Boolean =
        try {
            progressFile().writeText(payload)
            true
        } catch (e: Exception) {
            false
        }

    override fun onDestroy() {
        try {
            soundPool?.release()
            musicPlayer?.release()
            tts?.shutdown()
        } catch (e: Exception) {
            // ignore
        }
        super.onDestroy()
    }
}
