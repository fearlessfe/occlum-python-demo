#!/usr/bin/python3
import base64
import sys
import os

os.environ['OPENBLAS_NUM_THREADS'] = '1'

from flask import Flask, render_template, request
import cv2
from facedetector import FaceDetector
import imutils
import numpy as np

sys.path.insert(0, os.path.dirname(__file__))

app = Flask(__name__)
fd = FaceDetector("./resources/models/frontalface_default.xml")


@app.route('/',methods=['Get','Post'])
def hello():
    return render_template('index.html')

@app.route('/some_url',methods=['Get','Post'])
def first():
    return render_template('./first.html')

@app.route('/face_detect/', methods=['Get','Post'])
def face_detect():
    # img_data = base64.b64decode(image_code)
    # img_array = np.fromstring(img_data, np.uint8)
    # frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    local_image_path = request.args.get('local_image_path')
    print(local_image_path)

    frame = cv2.imread(local_image_path)

    frame = imutils.resize(frame, width = 300)
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    # detect faces in the image and then clone the frame
    # so that we can draw on it
    faceRects = fd.detect(gray, scaleFactor = 1.1, minNeighbors = 5,
                          minSize = (30, 30))
    frameClone = frame.copy()
    # loop over the face bounding boxes and draw them
    for (fX, fY, fW, fH) in faceRects:
        cv2.rectangle(frameClone, (fX, fY), (fX + fW, fY + fH), (0, 255, 0), -1)


    # decode
    image = cv2.imencode('.jpg', frameClone)[1]
    image_code = str(base64.b64encode(image))[2:-1]

    # img_data = base64.b64decode(image_code)
    # img_array = np.fromstring(img_data, np.uint8)
    # frameClone = cv2.imdecode(img_array, cv2.COLOR_RGB2BGR)
    # cv2.imshow("Face", frameClone)
    # while True:
    #     # if the 'q' key is pressed, stop the loop
    #     if cv2.waitKey(1) & 0xFF == ord("q"):
    #         break

    return image_code


if __name__ == '__main__':
    app.debug = False
    #ssl_context = (cert, cert_key)
    app.run(host='0.0.0.0', port=4996, threaded=True)#, ssl_context=ssl_context)
    #app.run(host='0.0.0.0', port=4996, threaded=True)
