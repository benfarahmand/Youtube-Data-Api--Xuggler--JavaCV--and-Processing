import com.google.gdata.client.Service;
import sample.util.SimpleCommandLineParser;
import com.google.gdata.client.youtube.YouTubeService;
import com.google.gdata.data.PlainTextConstruct;
import com.google.gdata.data.TextConstruct;
import com.google.gdata.data.media.MediaFileSource;
import com.google.gdata.data.media.mediarss.MediaCategory;
import com.google.gdata.data.media.mediarss.MediaDescription;
import com.google.gdata.data.media.mediarss.MediaKeywords;
import com.google.gdata.data.media.mediarss.MediaPlayer;
import com.google.gdata.data.media.mediarss.MediaTitle;
import com.google.gdata.data.youtube.CommentEntry;
import com.google.gdata.data.youtube.PlaylistEntry;
import com.google.gdata.data.youtube.PlaylistFeed;
import com.google.gdata.data.youtube.PlaylistLinkEntry;
import com.google.gdata.data.youtube.PlaylistLinkFeed;
import com.google.gdata.data.youtube.UserEventEntry;
import com.google.gdata.data.youtube.UserEventFeed;
import com.google.gdata.data.youtube.VideoEntry;
import com.google.gdata.data.youtube.VideoFeed;
import com.google.gdata.data.youtube.YouTubeMediaGroup;
import com.google.gdata.data.youtube.YouTubeNamespace;
import com.google.gdata.data.youtube.YtPublicationState;
import com.google.gdata.util.AuthenticationException;
import com.google.gdata.util.ServiceException;

import javax.mail.MessagingException;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class YouTubeUpload extends Thread {

  public boolean running, upload;          
  private int wait;  
  YouTubeService service;
  public static final String VIDEO_UPLOAD_FEED = "http://uploads.gdata.youtube.com/feeds/api/users/default/uploads";
  String devKey = ""; //dev key needed
  String currentFileName, currentFileFormat;

  public YouTubeUpload(int w) {
    wait = w;
    service = new YouTubeService("Art_Project", devKey);
    try {
      service.setUserCredentials("username", "password");
    } 
    catch (AuthenticationException e) {
      println("Invalid login credentials.");
    }
    println("Login to Youtube Successful!");
  }

  public void start() {
    running = true;
    upload = false;
    super.start();
  }

  public void run() {
    while (running) {
      if (upload) {
        File videoFile = new File("D:/get_put_video/"+currentFileName+currentFileFormat);
        if (!videoFile.exists()) {
          println("Sorry, that video doesn't exist.");
          return;
        }
        String mimeType = "video/mp4";
        String videoTitle = currentFileName;

        VideoEntry newEntry = new VideoEntry();
        YouTubeMediaGroup mg = newEntry.getOrCreateMediaGroup();

        mg.addCategory(new MediaCategory(YouTubeNamespace.CATEGORY_SCHEME, "Tech"));
        mg.setTitle(new MediaTitle());
        mg.getTitle().setPlainTextContent(videoTitle);
        mg.setKeywords(new MediaKeywords());
        mg.getKeywords().addKeyword("gdata-test");
        mg.setDescription(new MediaDescription());
        mg.getDescription().setPlainTextContent(videoTitle);
        MediaFileSource ms = new MediaFileSource(videoFile, mimeType);
        newEntry.setMediaSource(ms);

        try {
          service.insert(new URL(VIDEO_UPLOAD_FEED), newEntry);
        } 
        catch(IOException e) {
          println(e);
        }
        catch (ServiceException se) {
          println("Sorry, your upload was invalid:");
          println(se.getResponseBody());
          return;
        }
        println("Video "+currentFileName+" uploaded successfully!");
        upload = false;
        videoFile = null;
        newEntry = null;
        mg = null;
      }
      try {
        System.gc();
        sleep((long)(wait));
      }
      catch (Exception e) {
      }
    }
  }

  private void uploadVideo(String fileName, String fileFormat) {
    currentFileName = fileName;
    currentFileFormat = fileFormat;
    upload = true;
  }

  public void quit()
  {
    interrupt(); 
    try {
      sleep(100l);
    } 
    catch (Exception e) {
    }
  }
}

