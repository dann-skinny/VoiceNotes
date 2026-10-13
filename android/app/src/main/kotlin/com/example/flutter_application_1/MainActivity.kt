
package com.example.flutter_application_1

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "lifeflow/telefono"
    private val requestCode = 501

    private var numeroPendiente: String? = null
    private var resultadoPendiente: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->

            if (call.method == "llamar") {
                val numero = call.argument<String>("numero")

                if (numero.isNullOrBlank() ||
                    !numero.matches(Regex("\\+?[0-9]{7,15}"))
                ) {
                    result.error(
                        "NUMERO_INVALIDO",
                        "El número no es válido.",
                        null
                    )
                } else if (resultadoPendiente != null) {
                    result.error(
                        "LLAMADA_PENDIENTE",
                        "Ya hay una solicitud de llamada pendiente.",
                        null
                    )
                } else {
                    solicitarLlamada(numero, result)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun solicitarLlamada(
        numero: String,
        result: MethodChannel.Result
    ) {
        val permiso = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CALL_PHONE
        )

        if (permiso == PackageManager.PERMISSION_GRANTED) {
            realizarLlamada(numero, result)
        } else {
            numeroPendiente = numero
            resultadoPendiente = result

            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CALL_PHONE),
                requestCode
            )
        }
    }

    private fun realizarLlamada(
        numero: String,
        result: MethodChannel.Result
    ) {
        try {
            val intent = Intent(
                Intent.ACTION_CALL,
                Uri.fromParts("tel", numero, null)
            )

            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "ERROR_LLAMADA",
                "No se pudo iniciar la llamada: ${e.message}",
                null
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )

        if (requestCode == this.requestCode) {
            val numero = numeroPendiente
            val resultado = resultadoPendiente

            numeroPendiente = null
            resultadoPendiente = null

            if (resultado != null) {
                if (
                    grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED &&
                    numero != null
                ) {
                    realizarLlamada(numero, resultado)
                } else {
                    resultado.error(
                        "PERMISO_DENEGADO",
                        "Se necesita permiso para realizar llamadas.",
                        null
                    )
                }
            }
        }
    }
}
