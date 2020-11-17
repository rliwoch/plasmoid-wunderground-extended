/*
 * Copyright 2020  Kevin Donnelly
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "../code/utils.js" as Utils
import "../code/pws-api.js" as StationAPI

Item {
    id: root

    property var weatherData: null
    property string errorStr: ""
    property string toolTipSubText: ""
    property string iconCode: "32" // sunny
    property string conditionNarrative: ""


    property int showCONFIG: 1
    property int showLOADING: 2
    property int showERROR: 4
    property int showDATA: 8

    property int appState: showCONFIG

    property string stationID: plasmoid.configuration.stationID
    property int unitsChoice: plasmoid.configuration.unitsChoice

    property bool inTray: false

    property Component fr: FullRepresentation {
        Layout.preferredWidth: 480
        Layout.preferredHeight: 320
        Layout.minimumWidth: 480
        Layout.minimumHeight: 320
    }

    property Component cr: CompactRepresentation {
        Layout.minimumWidth: 110
        Layout.preferredWidth: 110
    }

    function printDebug(msg) {
        console.log("[debug] " + msg)
    }

    function updateWeatherData() {
        printDebug("getting new weather data")

        StationAPI.getWeatherData()
    }

    function updatetoolTipSubText() {
        var subText = ""

        subText += "<font size='4'>" + Utils.currentTempUnit(weatherData["details"]["temp"]) + "</font><br />"
        subText += "<font size='4'>" + Utils.currentSpeedUnit(weatherData["details"]["windSpeed"]) + "</font><br />"
        subText += "<br />"
        subText += "<font size='4'>" + weatherData["obsTimeLocal"] + "</font>"

        toolTipSubText = subText;
    }

    onUnitsChoiceChanged: {
        printDebug("units changed")

        // Show loading screen after units change
        appState = showLOADING;

        updateWeatherData()
    }

    onStationIDChanged: {
        printDebug("id changed")

        // Show loading screen after ID change
        appState = showLOADING;

        StationAPI.getWeatherData()
    }

    onWeatherDataChanged: {
        printDebug("weather data changed")

        updatetoolTipSubText()

        Utils.findIconCode()
    }

    onAppStateChanged: {
        printDebug("state is: " + appState)

        updatetoolTipSubText()
    }

    Component.onCompleted: {
        inTray = (plasmoid.parent !== null && (plasmoid.parent.pluginName === 'org.kde.plasma.private.systemtray' || plasmoid.parent.objectName === 'taskItemContainer'))

        plasmoid.configurationRequiredReason = "Set the weather station to pull data from."
    }

    Timer {
        interval: 10 * 1000
        running: appState == showDATA
        repeat: true
        onTriggered: updateWeatherData()
    }

    Plasmoid.toolTipTextFormat: Text.RichText
    Plasmoid.toolTipMainText: {
        if (appState == showCONFIG) {
            return "Please Configure";
        } else if (appState == showDATA) {
            return stationID;
        } else if (appState == showLOADING) {
            return "Loading...";
        } else if (appState == showERROR) {
            return "Error..."
        }
    }
    Plasmoid.toolTipSubText: toolTipSubText

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.fullRepresentation: fr
    Plasmoid.compactRepresentation: cr

}
