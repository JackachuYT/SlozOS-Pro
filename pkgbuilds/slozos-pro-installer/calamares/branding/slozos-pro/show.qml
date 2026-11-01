/* SlozOS Pro installer slideshow (Calamares slideshow API 2) */
import QtQuick
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function nextSlide() { presentation.goToNextSlide() }
    Timer { id: advance; interval: 12000; running: presentation.activatedInCalamares; repeat: true; onTriggered: nextSlide() }

    component Card: Slide {
        id: card
        property string heading
        property string body
        Image {
            anchors.fill: parent
            source: "background.jpg"
            fillMode: Image.PreserveAspectCrop
        }
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.78, 620)
            height: column.implicitHeight + 56
            radius: 22
            color: Qt.rgba(0.06, 0.12, 0.09, 0.72)
            border.color: Qt.rgba(1, 1, 1, 0.16)
            Column {
                id: column
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 32 }
                spacing: 14
                Text { text: card.heading; color: "white"; font.pixelSize: 30; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; width: parent.width }
                Text { text: card.body; color: Qt.rgba(1, 1, 1, 0.86); font.pixelSize: 17; wrapMode: Text.WordWrap; width: parent.width; lineHeight: 1.2 }
            }
        }
    }

    Card { heading: "Welcome to SlozOS Pro"; body: "Sit back while SlozOS Pro installs. It takes a few minutes, and it's ready for touch the moment it starts." }
    Card { heading: "Made for your fingers"; body: "Take the keyboard off and SlozOS Pro switches to tablet mode: bigger controls, and a keyboard pops up whenever you tap a text box. Turn it sideways and the screen follows." }
    Card { heading: "Swipe around"; body: "Swipe up from the bottom edge to see all your windows. Pinch to zoom in photos and web pages." }
    Card { heading: "Light and quick"; body: "Compressed memory keeps 4 GB tablets smooth, and nothing indexes your files in the background unless you ask it to." }

    function onActivate() { presentation.currentSlide = 0 }
    function onLeave() { }
}
