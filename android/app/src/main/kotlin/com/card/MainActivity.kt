package com.card

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 为 Android 8.0+ 创建高优先级通知渠道
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "high_importance_channel"

            val channel = NotificationChannel(
                channelId,
                "High Importance Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.enableVibration(true)
            channel.enableLights(true)

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)

            // 🔥 关键：立刻发一条本地通知，强制注册 channel（Android 9 必杀技）
            val notification = Notification.Builder(this, channelId)
                .setContentTitle("初始化通知")
                .setContentText("用于激活通知通道")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .build()

            manager.notify(1, notification)
            
            // 立即取消测试通知（channel 已激活）
            manager.cancel(1)
        }
    }
}
