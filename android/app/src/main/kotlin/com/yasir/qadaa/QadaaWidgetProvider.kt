package com.yasir.qadaa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QadaaWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val streak = widgetData.getInt("streak", 0)
        val totalDebt = widgetData.getInt("total_debt", 0)
        val fajrDone = widgetData.getBoolean("fajr_done", false)
        val dhuhrDone = widgetData.getBoolean("dhuhr_done", false)
        val asrDone = widgetData.getBoolean("asr_done", false)
        val maghribDone = widgetData.getBoolean("maghrib_done", false)
        val ishaDone = widgetData.getBoolean("isha_done", false)

        val streakText = if (streak > 0) "🔥 $streak" else "—"
        val debtText = "Debt: ${formatNumber(totalDebt)}"

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.qadaa_widget)

            views.setTextViewText(R.id.widget_streak, streakText)
            views.setTextViewText(R.id.widget_debt, debtText)
            views.setTextViewText(R.id.fajr_status, if (fajrDone) "✓" else "○")
            views.setTextViewText(R.id.dhuhr_status, if (dhuhrDone) "✓" else "○")
            views.setTextViewText(R.id.asr_status, if (asrDone) "✓" else "○")
            views.setTextViewText(R.id.maghrib_status, if (maghribDone) "✓" else "○")
            views.setTextViewText(R.id.isha_status, if (ishaDone) "✓" else "○")

            // Click: open app for title tap
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingLaunch = android.app.PendingIntent.getActivity(
                    context, 0, launchIntent,
                    android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_title, pendingLaunch)
            }

            // Click: prayer tap callbacks (increment count in background Dart isolate)
            views.setOnClickPendingIntent(
                R.id.btn_fajr,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context, Uri.parse("qadaaWidget://tap?prayer=fajr")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_dhuhr,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context, Uri.parse("qadaaWidget://tap?prayer=dhuhr")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_asr,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context, Uri.parse("qadaaWidget://tap?prayer=asr")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_maghrib,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context, Uri.parse("qadaaWidget://tap?prayer=maghrib")
                )
            )
            views.setOnClickPendingIntent(
                R.id.btn_isha,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context, Uri.parse("qadaaWidget://tap?prayer=isha")
                )
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun formatNumber(n: Int): String {
        return String.format("%,d", n)
    }
}
