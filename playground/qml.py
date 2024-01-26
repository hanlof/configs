import sys
import urllib.request
import json

from pathlib import Path
from PySide6.QtQuick import QQuickView
from PySide6.QtCore import QStringListModel, QUrl
from PySide6.QtGui import QGuiApplication


app = QGuiApplication(sys.argv)
view = QQuickView()
view.setResizeMode(QQuickView.SizeRootObjectToView)

my_model = QStringListModel()
my_model.setStringList(["a", "b", "c"])
view.setInitialProperties({"myModel": my_model})

qml_file = Path(__file__).parent / "view.qml"
view.setSource(QUrl.fromLocalFile(qml_file.resolve()))

if view.status() == QQuickView.Error:
    sys.exit(-1)

view.show()

#execute and cleanup
app.exec()
del view
