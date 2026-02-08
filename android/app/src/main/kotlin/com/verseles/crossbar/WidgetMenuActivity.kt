package com.verseles.crossbar

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

/**
 * Lightweight Activity that displays plugin menu items as a bottom-sheet-like dialog.
 * Built programmatically without Material Components dependency.
 * Receives pluginId via Intent extra, reads menu data from SharedPreferences.
 */
class WidgetMenuActivity : Activity() {

    companion object {
        const val EXTRA_PLUGIN_ID = "plugin_id"
        private const val TAG = "WidgetMenuActivity"
    }

    private val isDarkMode: Boolean
        get() = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val pluginId = intent.getStringExtra(EXTRA_PLUGIN_ID)
        if (pluginId == null) {
            finish()
            return
        }

        val widgetData = HomeWidgetPlugin.getData(this)
        val pluginDataJson = widgetData.getString("plugin_$pluginId", null)
        if (pluginDataJson == null) {
            finish()
            return
        }

        val pluginData = try {
            JSONObject(pluginDataJson)
        } catch (e: Exception) {
            finish()
            return
        }

        val menuArray = pluginData.optJSONArray("menu")
        if (menuArray == null || menuArray.length() == 0) {
            finish()
            return
        }

        val icon = pluginData.optString("icon", "")
        val rawTitle = pluginData.optString("title", "")
        val title = rawTitle.ifBlank { pluginData.optString("pluginId", "Plugin") }

        buildUI(icon, title, menuArray)
    }

    private fun buildUI(icon: String, title: String, menuArray: JSONArray) {
        val bgColor = if (isDarkMode) Color.parseColor("#1E1E1E") else Color.WHITE
        val textColor = if (isDarkMode) Color.WHITE else Color.parseColor("#1E1E1E")
        val secondaryText = if (isDarkMode) Color.parseColor("#B0B0B0") else Color.parseColor("#666666")
        val dividerColor = if (isDarkMode) Color.parseColor("#333333") else Color.parseColor("#E0E0E0")
        val scrimColor = Color.parseColor("#80000000")
        val accentColor = if (isDarkMode) Color.parseColor("#90CAF9") else Color.parseColor("#1976D2")

        val dp = { value: Float ->
            TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()
        }

        // Root: scrim overlay
        val root = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(scrimColor)
            setOnClickListener { finish() }
        }

        // Card container at bottom
        val cardBg = GradientDrawable().apply {
            setColor(bgColor)
            cornerRadii = floatArrayOf(
                dp(16f).toFloat(), dp(16f).toFloat(),
                dp(16f).toFloat(), dp(16f).toFloat(),
                0f, 0f, 0f, 0f
            )
        }

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = cardBg
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.BOTTOM
            }
            // Limit max height to 70% of screen
            val maxH = (resources.displayMetrics.heightPixels * 0.7).toInt()
            post {
                if (height > maxH) {
                    layoutParams.height = maxH
                    requestLayout()
                }
            }
            // Prevent clicks from dismissing through the card
            setOnClickListener { /* consume */ }
        }

        // Handle bar
        val handleBar = View(this).apply {
            val handleBg = GradientDrawable().apply {
                setColor(dividerColor)
                cornerRadius = dp(2f).toFloat()
            }
            background = handleBg
            layoutParams = LinearLayout.LayoutParams(dp(40f), dp(4f)).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                topMargin = dp(8f)
                bottomMargin = dp(4f)
            }
        }
        card.addView(handleBar)

        // Header: icon + title
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(16f), dp(12f), dp(16f), dp(12f))
        }

        if (icon.isNotBlank()) {
            val iconView = TextView(this).apply {
                text = icon
                textSize = 24f
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    marginEnd = dp(12f)
                }
            }
            header.addView(iconView)
        }

        val titleView = TextView(this).apply {
            text = formatPluginTitle(title)
            textSize = 18f
            setTextColor(textColor)
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        header.addView(titleView)

        card.addView(header)

        // Divider
        card.addView(createDivider(dividerColor, dp))

        // ScrollView with menu items
        val scrollView = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val menuContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(0, dp(4f), 0, dp(8f))
        }

        renderMenuItems(menuArray, menuContainer, textColor, secondaryText, dividerColor, accentColor, dp, 0)

        scrollView.addView(menuContainer)
        card.addView(scrollView)

        root.addView(card)
        setContentView(root)
    }

    private fun renderMenuItems(
        items: JSONArray,
        container: LinearLayout,
        textColor: Int,
        secondaryText: Int,
        dividerColor: Int,
        accentColor: Int,
        dp: (Float) -> Int,
        indentLevel: Int
    ) {
        for (i in 0 until items.length()) {
            val item = items.optJSONObject(i) ?: continue

            val isSeparator = item.optBoolean("separator", false)
            if (isSeparator) {
                container.addView(createDivider(dividerColor, dp))
                continue
            }

            val text = item.optString("text", "").trim()
            if (text.isEmpty()) continue

            val href = item.optString("href", "")
            val bash = item.optString("bash", "")
            val itemColorHex = item.optString("color", "")
            val submenu = item.optJSONArray("submenu")

            val hasHref = href.isNotBlank()
            val hasBash = bash.isNotBlank()

            val itemView = TextView(this).apply {
                this.text = if (hasBash && !hasHref) "$text (Desktop)" else text
                textSize = 15f
                val baseColor = when {
                    itemColorHex.isNotBlank() -> {
                        try {
                            Color.parseColor(if (itemColorHex.startsWith("#")) itemColorHex else "#$itemColorHex")
                        } catch (e: Exception) {
                            textColor
                        }
                    }
                    hasHref -> accentColor
                    hasBash -> secondaryText
                    else -> textColor
                }
                setTextColor(baseColor)

                if (hasBash && !hasHref) {
                    alpha = 0.5f
                }

                val leftPad = dp(16f) + (indentLevel * dp(16f))
                setPadding(leftPad, dp(14f), dp(16f), dp(14f))

                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )

                if (hasHref) {
                    setOnClickListener {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(href))
                            startActivity(intent)
                        } catch (e: Exception) {
                            android.util.Log.e(TAG, "Failed to open URL: $href", e)
                        }
                        finish()
                    }
                } else if (!hasBash) {
                    // Info items: copy text to clipboard on tap
                    setOnClickListener {
                        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        clipboard.setPrimaryClip(ClipData.newPlainText("Crossbar", text))
                        Toast.makeText(this@WidgetMenuActivity, "Copied", Toast.LENGTH_SHORT).show()
                    }
                }

                // Show ripple for all interactive items (not bash-disabled)
                if (!hasBash) {
                    val outValue = TypedValue()
                    theme.resolveAttribute(android.R.attr.selectableItemBackground, outValue, true)
                    setBackgroundResource(outValue.resourceId)
                }
            }
            container.addView(itemView)

            // Render submenu items inline with extra indentation
            if (submenu != null && submenu.length() > 0) {
                renderMenuItems(submenu, container, textColor, secondaryText, dividerColor, accentColor, dp, indentLevel + 1)
            }
        }
    }

    private fun createDivider(color: Int, dp: (Float) -> Int): View {
        return View(this).apply {
            setBackgroundColor(color)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(1f)
            ).apply {
                leftMargin = dp(16f)
                rightMargin = dp(16f)
            }
        }
    }

    private fun formatPluginTitle(pluginId: String): String {
        return pluginId
            .substringBefore(".")
            .replaceFirstChar { it.uppercase() }
    }
}
