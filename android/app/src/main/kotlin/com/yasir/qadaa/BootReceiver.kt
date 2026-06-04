package com.yasir.qadaa

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

// Triggers a widget redraw after device boot so prayer state is visible on the home screen.
// Notification rescheduling after boot is handled automatically by
// flutter_local_notifications' ScheduledNotificationBootReceiver.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val manager = AppWidgetManager.getInstance(context)
        val widgetIds = manager.getAppWidgetIds(
            ComponentName(context, QadaaWidgetProvider::class.java)
        )
        if (widgetIds.isNotEmpty()) {
            val updateIntent = Intent(context, QadaaWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
            }
            context.sendBroadcast(updateIntent)
        }
    }
}
