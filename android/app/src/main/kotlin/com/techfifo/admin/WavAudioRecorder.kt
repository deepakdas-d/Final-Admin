package com.techfifo.admin

import android.content.Context
import android.media.*
import android.util.Log
import java.io.*
import android.os.Environment
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import android.os.Build


class WavAudioRecorder {
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private lateinit var recordingThread: Thread
    private lateinit var wavFile: File
    private lateinit var wavOut: DataOutputStream
    private var totalAudioLen = 0

    // Audio settings
    private val sampleRate = 44100
    private val channels = 1
    private val bitsPerSample = 16

    /**
     * Check if a wired headset is connected using AudioManager
     */
    fun isWiredHeadsetPlugged(context: Context): Boolean {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
        return devices.any { 
            it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET || 
            it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES 
        }
    }

    /**
     * Legacy check for wired headset connection (may not work reliably on newer Android)
     */
    private fun isWiredHeadsetOn(context: Context): Boolean {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return audioManager.isWiredHeadsetOn
    }

    /**
     * Start recording audio and write it to a WAV file in Downloads/salesperson_audio
     */
    fun startRecording(context: Context) {
    Log.d("AudioRecord", "Starting recording...")

    val channelConfig = AudioFormat.CHANNEL_IN_MONO
    val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

    // ✅ App-private Downloads folder for Android 10+
    val folder: File = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        File(context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), "salesperson_audio")
    } else {
        File(context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), "salesperson_audio")
    }

    // 📁 Ensure folder exists
    if (!folder.exists()) {
        val created = folder.mkdirs()
        Log.d("AudioRecord", "Created folder: ${folder.absolutePath}, success: $created")
    } else {
        Log.d("AudioRecord", "Using existing folder: ${folder.absolutePath}")
    }

    // 🎙 Generate timestamped filename
    val timestamp = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault()).format(Date())
    val fileName = "recording_$timestamp.wav"
    wavFile = File(folder, fileName)
    Log.d("AudioRecord", "Output file: ${wavFile.absolutePath}")

    // 📝 Write WAV header
    wavOut = DataOutputStream(BufferedOutputStream(FileOutputStream(wavFile)))
    writeWavHeader(wavOut)
    Log.d("AudioRecord", "WAV header written")

    // 🎧 Select best audio source
    val selectedAudioSource = if (isWiredHeadsetOn(context)) {
        MediaRecorder.AudioSource.VOICE_COMMUNICATION
    } else {
        MediaRecorder.AudioSource.MIC
    }

    // 🎛 Initialize recorder
    audioRecord = AudioRecord(
        selectedAudioSource,
        sampleRate,
        channelConfig,
        audioFormat,
        bufferSize
    )

    isRecording = true
    audioRecord?.startRecording()
    Log.d("AudioRecord", "AudioRecord started")

    // 💾 Background thread to write audio data
    recordingThread = Thread {
        val buffer = ByteArray(bufferSize)
        while (isRecording) {
            val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
            if (read > 0) {
                totalAudioLen += read
                wavOut.write(buffer, 0, read)
                Log.d("AudioRecord", "Read $read bytes")
            } else {
                Log.e("AudioRecord", "No data read: $read")
            }
        }
        Log.d("AudioRecord", "Recording thread stopped")
    }
    recordingThread.start()
}


    /**
     * Stop recording, finalize the WAV file, update header with correct sizes
     */
    fun stopRecording() {
        Log.d("AudioRecord", "Stopping recording...")
        isRecording = false

        try {
            audioRecord?.stop()
            audioRecord?.release()
            recordingThread.join()
            wavOut.close()
            Log.d("AudioRecord", "Total audio length: $totalAudioLen")
            updateWavHeader(wavFile, totalAudioLen)
            Log.d("AudioRecord", "WAV file saved at: ${wavFile.absolutePath}, size: ${wavFile.length()} bytes")
        } catch (e: Exception) {
            Log.e("AudioRecord", "Error during stopRecording: ${e.message}")
        }
    }

    /**
     * Write placeholder WAV header. Will update later in updateWavHeader
     */
    private fun writeWavHeader(out: DataOutputStream) {
        val byteRate = sampleRate * channels * bitsPerSample / 8
        out.writeBytes("RIFF")
        out.writeIntLE(0) // Placeholder for total file length
        out.writeBytes("WAVE")
        out.writeBytes("fmt ")
        out.writeIntLE(16) // Subchunk1 size (PCM)
        out.writeShortLE(1.toShort()) // Audio format (1 = PCM)
        out.writeShortLE(channels.toShort())
        out.writeIntLE(sampleRate)
        out.writeIntLE(byteRate)
        out.writeShortLE((channels * bitsPerSample / 8).toShort()) // Block align
        out.writeShortLE(bitsPerSample.toShort())
        out.writeBytes("data")
        out.writeIntLE(0) // Placeholder for data chunk size
    }

    /**
     * Update WAV header with correct file and data lengths
     */
    private fun updateWavHeader(file: File, audioDataSize: Int) {
        val randomAccessFile = RandomAccessFile(file, "rw")
        val totalDataLen = 36 + audioDataSize
        randomAccessFile.seek(4)
        randomAccessFile.writeIntLE(totalDataLen)
        randomAccessFile.seek(40)
        randomAccessFile.writeIntLE(audioDataSize)
        randomAccessFile.close()
    }

    // Helper: Write little-endian int to DataOutputStream
    private fun DataOutputStream.writeIntLE(value: Int) {
        write(value and 0xff)
        write(value shr 8 and 0xff)
        write(value shr 16 and 0xff)
        write(value shr 24 and 0xff)
    }

    // Helper: Write little-endian short to DataOutputStream
    private fun DataOutputStream.writeShortLE(value: Short) {
        write(value.toInt() and 0xff)
        write(value.toInt() shr 8 and 0xff)
    }

    // Helper: Write little-endian int to RandomAccessFile
    private fun RandomAccessFile.writeIntLE(value: Int) {
        write(value and 0xff)
        write(value shr 8 and 0xff)
        write(value shr 16 and 0xff)
        write(value shr 24 and 0xff)
    }

    fun getOutputPath(): String {
    return wavFile.absolutePath
    }

}