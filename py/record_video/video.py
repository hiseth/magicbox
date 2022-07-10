import threading
import time

import keyboard
import pyaudio
import wave
import numpy as np
import cv2 as cv
import faulthandler
from PIL import ImageGrab
from moviepy.editor import *
from cv2 import VideoCapture, CAP_PROP_FPS, CAP_PROP_FRAME_COUNT, CAP_PROP_FRAME_WIDTH, CAP_PROP_FRAME_HEIGHT

CHUNK = 1024
FORMAT = pyaudio.paInt16
CHANNELS = 2
RATE = 48000
# RECORD_SECONDS = 20
WAVE_OUTPUT_NAME = 'test-audio.wav'
global flag
flag = True

faulthandler.enable()


def get_audio_device():
    p = pyaudio.PyAudio()
    for i in range(p.get_device_count()):
        ava_device = p.get_device_info_by_index(i)
        if ava_device['hostApi'] == 0 and ava_device['maxInputChannels'] == 2:
            print(ava_device['index'], ava_device['name'])
    dev_id = input("Enter your device id: ")

    return int(dev_id)


def record_video():
    # Screen Size (windows using pywin32)
    image = ImageGrab.grab()
    width = image.size[0]
    height = image.size[1]

    fourcc = cv.VideoWriter_fourcc(*'XVID')
    output_video = cv.VideoWriter('test-video.avi', fourcc, 1, image.size)


    while flag:
        im = ImageGrab.grab()
        # rgb > bgr
        im = cv.cvtColor(np.array(im), cv.COLOR_RGB2BGR)
        output_video.write(im)
        # cv2.imshow('imm', img_bgr)

    output_video.release()
    # cv2.destroyAllWindows()


def record_audio():
    p = pyaudio.PyAudio()
    # INPUT_DEVICE = get_audio_device()
    stream = p.open(format=FORMAT,
                    channels=CHANNELS,
                    rate=RATE,
                    input=True,
                    # output=True,
                    input_device_index=get_audio_device(),
                    frames_per_buffer=CHUNK
                    )

    wf = wave.open(WAVE_OUTPUT_NAME, 'wb')
    wf.setnchannels(CHANNELS)
    wf.setsampwidth(p.get_sample_size(FORMAT))
    wf.setframerate(RATE)

    # for i in range(0, int(RATE / CHUNK * RATEECORD_SECONDS)):
    while flag:
        data = stream.read(CHUNK, exception_on_overflow=False)
        # frames.append(data)
        wf.writeframes(data)

    wf.close()
    stream.stop_stream()
    stream.close()

    p.terminate()


def run_record():
    t1 = threading.Thread(target=record_video)
    t2 = threading.Thread(target=record_audio)

    for t in [t1, t2]:
        t.start()

    while True:
        if keyboard.record(until='esc'):
            break
    global flag
    flag = False
    for t in [t1, t2]:
        t.join()

    video = VideoFileClip('test-video.avi')
    audio = AudioFileClip('test-audio.wav')
    video.set_audio(audio)

    video.write_videofile('ult-video.avi', codec='png', fps=1)


if __name__ == '__main__':
    run_record()

