import com.xuggle.xuggler.*;
import com.xuggle.mediatool.*;
import com.xuggle.ferry.*; 
import java.awt.image.BufferedImage;
import java.awt.image.ImageObserver;
import java.util.concurrent.TimeUnit;
import javax.sound.sampled.*; 
//import com.googlecode.javacv.*;
//import com.googlecode.javacv.cpp.*;
import monclubelec.javacvPro.*;
import java.awt.*;
//import codeanticode.gsvideo.*;
import java.io.File;
import com.google.gdata.data.youtube.FeedLinkEntry;
import processing.video.*;

IMediaWriter imw;
IStreamCoder isc;
BufferedImage bgr;
int vidRate;
long sTime;
long fTime;

//GSCapture cam;
Capture cam;

final int audioStreamIndex = 1;
final int audioStreamId = 1;
final int channelCount = 2;
int sampleRate;

AudioFormat audioFormat;
AudioInputStream audioInputStream; 
TargetDataLine aline;
AudioFormat targetType;

byte[] audioBuf;
int audionumber;

int widthCapture=640;
int heightCapture=480;
flatlanderThread myThread;

boolean recording, processing;
int sentenceCounter;

String[] lines;
int index = 0;
File dir = new File("D:/get_put_video/");
String fileFormat = ".mp4";
PFont font;

YouTubeUpload ytu;
int maxTimer, savedTimer;
int totalTimer = 120000; //milliseconds, 5 minutes...

void setup() {
  recording = false;
  processing = false;
  font = loadFont("SansSerif.plain-48.vlw");
  vidRate = 30;
  frameRate(vidRate);
  size(displayWidth, displayHeight, JAVA2D); 
//  cam = new GSCapture(this, widthCapture, heightCapture, vidRate);
  cam = new Capture(this, widthCapture, heightCapture, vidRate);
  cam.start();
  myThread = new flatlanderThread(this, 50);
  myThread.start();
  avSetup();
  lines = loadStrings("modifiedText.txt");
  sentenceCounter = dir.list().length;
  println(sentenceCounter);
  ytu = new YouTubeUpload(250);
  ytu.start();
}


float angle;
void draw() {
  //UI stuff
  background(200);
  if (ytu.upload) {
    angle = angle + .1;
    pushMatrix();
    translate(width/2, height/2);
    rotate(angle);
    fill(180);
    noStroke();
    rect(-150, -150, 300, 300);
    popMatrix();
    fill(0);
    textSize(48);
    text("Processing", width*.425, height*.52);
  }
  else {
    textSize(38);
    fill(0);
    text("Sentence #"+sentenceCounter, width*.05, height*.95);
    text(split(lines[sentenceCounter], '~')[1], width*.05, height*.15, width*.9, height*.8);
  }
  textSize(42);
  text("Press record and read the sentence below. Press stop when you're done.", width*.02, height*.08);
  if (recording) {
    fill(230, 0, 0);
    noStroke();
    rect(width*.3, height*.9, width*.4, height*.1);
    fill(0);
    textSize(60);
    text("Recording", width*.42, height*.96);
  }
  stroke(0);
  strokeWeight(2);
  line(0, height*.13, width, height*.13);
  line(0, height*.9, width, height*.9);

  //video stuff
  if (recording) {
    maxTimer = millis() - savedTimer;
//    println(maxTimer);
    if (imw.isOpen()) {
      long cTime = System.nanoTime()-fTime;
      if (cTime >= (double)1000/vidRate) {
        bgr.getGraphics().drawImage(myThread.getTempBuffer().getImage(), 0, 0, 
        new ImageObserver() { 
          public boolean imageUpdate(Image i, int a, int b, int c, int d, int e) {
            return true;
          }
        }
        );
        imw.encodeVideo(0, bgr, System.nanoTime()-sTime, TimeUnit.NANOSECONDS);
        if (aline.available() == 88200) {
          int nBytesRead = aline.read(audioBuf, 0, aline.available());//audioBuf.length);//aline.available());
          if (nBytesRead>0) {
            IBuffer iBuf = IBuffer.make(null, audioBuf, 0, nBytesRead);
            IAudioSamples smp = IAudioSamples.make(iBuf, channelCount, IAudioSamples.Format.FMT_S16);

            if (smp!=null) {
              long numSample = nBytesRead/smp.getSampleSize();
              smp.setComplete(true, numSample, (int) audioFormat.getSampleRate(), audioFormat.getChannels(), IAudioSamples.Format.FMT_S16, (System.nanoTime()-sTime) / 1000);
              smp.put(audioBuf, 1, 0, aline.available()); 
              try {
                imw.encodeAudio(audionumber, smp);
              }
              catch(Exception e) {
                println("EXCEPTION: " + e);
              }
            }
          }
        }
        fTime = System.nanoTime();
      }
    }
    if(maxTimer>totalTimer) {
      imw.flush();
        imw.close();
        try {
          ytu.uploadVideo("sentence"+sentenceCounter, fileFormat);
        }
        catch (Exception e) {
          println(e);
        }
        sentenceCounter++;
        recording=false;
    }
  }
//  image(myThread.getTempBuffer(),0,0);
}

public void keyPressed() {
  if (!ytu.upload) {
    if (key == 'r') {
      println("recording");
      if (!recording) {
        avRecorderSetup();
        recording = true;
        savedTimer = millis();
      }
    }
    if (key == 's') {
      if (recording) {
        imw.flush();
        imw.close();
        try {
          ytu.uploadVideo("sentence"+sentenceCounter, fileFormat);
        }
        catch (Exception e) {
          println(e);
        }
        sentenceCounter++;
        recording = false;
      }
    }
  }
}

void avStop(){
  bgr = null;
  isc = null;
  imw = null;
}

void avSetup() {
  audioFormat = new AudioFormat(44100.0F, 16, channelCount, true, false); 
  sampleRate = (int) audioFormat.getSampleRate();
  DataLine.Info info = new DataLine.Info(TargetDataLine.class, audioFormat); 
  try { 
    aline = (TargetDataLine) AudioSystem.getLine(info); 
    aline.open(audioFormat);
    aline.start();
    println("audio line");
  } 
  catch (LineUnavailableException e) 
  { 
    println("unable to get a recording line"); 
    e.printStackTrace(); 
    exit();
  }
  int bufferSize = (int) audioFormat.getSampleRate() * audioFormat.getFrameSize();
  audioBuf = new byte[bufferSize];
  targetType = aline.getFormat();
  audioInputStream = new AudioInputStream(aline);
}

void avRecorderSetup() {
  imw = ToolFactory.makeWriter(sketchPath("D:/get_put_video/sentence"+sentenceCounter+fileFormat));//or "output.avi" or "output.mov"
  imw.open();
  imw.setForceInterleave(true);
  imw.addVideoStream(0, 0, IRational.make((double)vidRate), widthCapture, heightCapture);
  audionumber = imw.addAudioStream(audioStreamIndex, audioStreamId, channelCount, sampleRate);
  isc = imw.getContainer().getStream(0).getStreamCoder();
  bgr = new BufferedImage(widthCapture, heightCapture, BufferedImage.TYPE_3BYTE_BGR);
  sTime = fTime = System.nanoTime();
}

