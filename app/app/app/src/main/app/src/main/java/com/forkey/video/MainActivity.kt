package com.forkey.video

import android.app.Activity
import android.os.Bundle
import android.graphics.Color
import android.view.Gravity
import android.widget.*

class MainActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        layout.gravity = Gravity.CENTER
        layout.setBackgroundColor(Color.rgb(15, 15, 25))
        layout.setPadding(30, 30, 30, 30)

        val title = TextView(this)
        title.text = "ForKey Video"
        title.textSize = 32f
        title.setTextColor(Color.WHITE)
        title.gravity = Gravity.CENTER

        val subtitle = TextView(this)
        subtitle.text = "Video • Kreativitas • Komunitas"
        subtitle.textSize = 16f
        subtitle.setTextColor(Color.LTGRAY)
        subtitle.gravity = Gravity.CENTER

        val button = Button(this)
        button.text = "Mulai Menonton"
        button.setOnClickListener {
            Toast.makeText(
                this,
                "Selamat datang di ForKey Video!",
                Toast.LENGTH_SHORT
            ).show()
        }

        layout.addView(title)
        layout.addView(subtitle)
        layout.addView(button)

        setContentView(layout)
    }
}
