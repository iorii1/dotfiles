pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real temperature: 0
    property int weatherCode: 0
    property string cityName: ""
    property bool ready: false

    // The geolocation is already fetched to get the forecast; exposing it means
    // night light can place the sunset without geolocating a second time or
    // making anyone type coordinates.
    property real latitude: 0
    property real longitude: 0
    property bool hasLocation: false

    // Broad category for driving a themed animated icon.
    // https://open-meteo.com/en/docs#weathervariables
    function category(code) {
        if (code === 0 || code === 1) return "clear"
        if (code >= 95) return "thunder"
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "snow"
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "rain"
        return "cloud"
    }

    function refresh() {
        if (!root.cityName) {
            geoProc.running = true
        } else {
            weatherProc.running = true
        }
    }

    Process {
        id: geoProc
        command: ["curl", "-s", "--max-time", "5", "http://ip-api.com/json/"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    if (d.status === "success") {
                        root.cityName = d.city || ""
                        root.latitude = d.lat
                        root.longitude = d.lon
                        root.hasLocation = true
                        weatherProc.command = ["curl", "-s", "--max-time", "5",
                            "https://api.open-meteo.com/v1/forecast?latitude=" + d.lat +
                            "&longitude=" + d.lon + "&current=temperature_2m,weather_code"]
                        weatherProc.running = true
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: weatherProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    if (d.current) {
                        root.temperature = d.current.temperature_2m
                        root.weatherCode = d.current.weather_code
                        root.ready = true
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
